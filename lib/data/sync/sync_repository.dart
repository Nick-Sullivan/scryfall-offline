import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../db/db_files.dart';
import 'bulk_api.dart';
import 'downloader.dart';
import 'ingest_isolate.dart';
import 'sync_progress.dart';

/// Rough uncompressed bytes per card object, used only to give the ingest
/// progress bar a denominator.
const _bytesPerCard = 5300;

/// Orchestrates one full sync: resolve bulk URLs -> download -> ingest in an
/// isolate into a staging DB -> verify -> hand back for the atomic swap.
///
/// The caller (app layer) owns the live database handle; [run] stops at
/// "staging verified" and the caller performs the swap via
/// [DbFiles.swapStagingIntoLive] after closing the live DB.
class SyncRepository {
  final DbFiles files;
  final http.Client client;
  final String appVersion;

  /// Sanity floor for a real default_cards ingest; a truncated download or
  /// format break must never replace a good database.
  final int minExpectedCards;

  SyncRepository({
    required this.files,
    required this.client,
    required this.appVersion,
    this.minExpectedCards = 10000,
  });

  /// Emits progress; completes after staging verification with [SyncDone]
  /// (staging file left in place for the swap) or [SyncFailed].
  Stream<SyncProgress> run() {
    final controller = StreamController<SyncProgress>();
    _run(controller).whenComplete(controller.close);
    return controller.stream;
  }

  Future<void> _run(StreamController<SyncProgress> out) async {
    try {
      out.add(const SyncChecking());
      final index = await BulkApi(client, appVersion: appVersion).fetchIndex();

      files.syncDir.createSync(recursive: true);
      final cardsFile = File(p.join(files.syncDir.path,
          index.defaultCards.isGzip ? 'cards.jsonl.gz' : 'cards.json'));
      final rulingsFile = File(p.join(files.syncDir.path,
          index.rulings.isGzip ? 'rulings.jsonl.gz' : 'rulings.json'));

      var lastEmit = 0;
      Future<void> download(BulkFileInfo info, File target, String label) =>
          downloadFile(client, info.downloadUri, target,
              headers: scryfallHeaders(appVersion), onProgress: (recv, total) {
            // Throttle to ~every 256 KB so the UI isn't flooded.
            if (recv - lastEmit > 256 * 1024 || recv == total) {
              lastEmit = recv;
              out.add(SyncDownloading(label, recv, total));
            }
          });

      await download(index.defaultCards, cardsFile, 'cards');
      lastEmit = 0;
      await download(index.rulings, rulingsFile, 'rulings');

      final approxCards = index.defaultCards.size ~/ _bytesPerCard;
      final done = Completer<({int cards, int prints})>();
      final port = ReceivePort();
      port.listen((msg) {
        final map = msg as Map;
        switch (map['type']) {
          case 'cards':
            out.add(SyncIngesting('cards', map['n'] as int, approxCards));
          case 'rulings':
            out.add(SyncIngesting('rulings', map['n'] as int, 0));
          case 'finalizing':
            out.add(const SyncFinalizing());
          case 'done':
            done.complete(
                (cards: map['cards'] as int, prints: map['prints'] as int));
          case 'error':
            done.completeError(StateError(map['message'] as String));
        }
      });

      try {
        await Isolate.spawn(
          ingestIsolateMain,
          IngestRequest(
            progressPort: port.sendPort,
            stagingDbPath: files.staging.path,
            cardsPath: cardsFile.path,
            cardsGzip: index.defaultCards.isGzip,
            rulingsPath: rulingsFile.path,
            rulingsGzip: index.rulings.isGzip,
            bulkUpdatedAt: index.defaultCards.updatedAt,
            rulingsUpdatedAt: index.rulings.updatedAt,
          ),
          errorsAreFatal: true,
        );
        final stats = await done.future;

        if (stats.cards < minExpectedCards) {
          throw StateError(
              'ingest produced only ${stats.cards} cards — refusing to '
              'replace the database');
        }
        // Downloads are no longer needed once staging is verified.
        for (final f in [cardsFile, rulingsFile]) {
          if (f.existsSync()) f.deleteSync();
        }
        out.add(SyncDone(stats.cards, stats.prints));
      } finally {
        port.close();
      }
    } catch (e) {
      if (files.staging.existsSync()) files.staging.deleteSync();
      out.add(SyncFailed(e.toString()));
    }
  }

  /// One cheap API call comparing the server's updated_at with ours.
  Future<bool> updateAvailable(String? currentUpdatedAt) async {
    final index = await BulkApi(client, appVersion: appVersion).fetchIndex();
    return currentUpdatedAt == null ||
        index.defaultCards.updatedAt != currentUpdatedAt;
  }
}
