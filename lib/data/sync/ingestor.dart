import 'dart:async';

import 'package:drift/drift.dart';

import '../db/database.dart';
import '../db/tables.dart';
import 'card_extractor.dart';

class IngestStats {
  int cards = 0;
  int faces = 0;
  int prints = 0;
  int rulings = 0;
}

/// Pure ingest core: consumes decoded bulk objects and writes batched rows
/// into [db]. Platform-independent so the whole pipeline runs on the Dart VM
/// in tests; isolate/file plumbing lives in sync_repository.dart.
class Ingestor {
  static const _batchSize = 800;

  final AppDatabase db;
  final void Function(int processed)? onProgress;

  final _extractor = CardExtractor();
  final _stats = IngestStats();

  Ingestor(this.db, {this.onProgress});

  IngestStats get stats => _stats;

  Future<void> ingestCards(Stream<Map<String, dynamic>> objects) async {
    var cards = <CardsCompanion>[];
    var faces = <FacesCompanion>[];
    var prints = <PrintsCompanion>[];
    var processed = 0;

    Future<void> flush() async {
      if (cards.isEmpty && prints.isEmpty) return;
      final c = cards, f = faces, p = prints;
      cards = [];
      faces = [];
      prints = [];
      await db.batch((b) {
        b.insertAll(db.cards, c);
        b.insertAll(db.faces, f);
        b.insertAll(db.prints, p, mode: InsertMode.insertOrReplace);
      });
    }

    await for (final json in objects) {
      final extracted = _extractor.extract(json);
      if (extracted == null) continue;
      if (extracted.card != null) {
        cards.add(extracted.card!);
        faces.addAll(extracted.faces);
        _stats.cards++;
        _stats.faces += extracted.faces.length;
      }
      prints.add(extracted.print);
      _stats.prints++;
      processed++;
      if (prints.length >= _batchSize) {
        await flush();
        onProgress?.call(processed);
      }
    }
    await flush();
    onProgress?.call(processed);
  }

  Future<void> ingestRulings(Stream<Map<String, dynamic>> objects) async {
    var rows = <RulingsCompanion>[];

    Future<void> flush() async {
      if (rows.isEmpty) return;
      final r = rows;
      rows = [];
      await db.batch((b) => b.insertAll(db.rulings, r));
    }

    await for (final json in objects) {
      final oracleId = json['oracle_id'] as String?;
      if (oracleId == null) continue;
      rows.add(RulingsCompanion.insert(
        oracleId: oracleId,
        publishedAt: json['published_at'] as String? ?? '',
        comment: json['comment'] as String? ?? '',
      ));
      _stats.rulings++;
      if (rows.length >= _batchSize) await flush();
    }
    await flush();
  }

  /// Derived data that needs the full card set: earliest release date,
  /// preferred (representative) print per card, FTS indexes, statistics.
  Future<void> finalize(
      {String? bulkUpdatedAt,
      String? rulingsUpdatedAt,
      int? setsCardTotal}) async {
    await db.customStatement('''
      UPDATE cards SET released_at_first = COALESCE((
        SELECT MIN(p.released_at) FROM prints p
        WHERE p.oracle_id = cards.oracle_id AND p.released_at > 0
      ), released_at_first)
    ''');
    await db.customStatement('''
      UPDATE cards SET preferred_print_id = (
        SELECT p.id FROM prints p
        WHERE p.oracle_id = cards.oracle_id
        ORDER BY (p.lang = 'en') DESC,
                 (p.flags & ${PrintFlag.digital}) = 0 DESC,
                 (p.flags & ${PrintFlag.promo}) = 0 DESC,
                 (p.flags & ${PrintFlag.highres}) != 0 DESC,
                 p.released_at DESC
        LIMIT 1
      )
    ''');
    await db.rebuildFtsIndexes();
    await db.customStatement('ANALYZE');

    final now = DateTime.now().toUtc().toIso8601String();
    final entries = {
      MetaKeys.schemaVersion: '$schemaVersionValue',
      MetaKeys.cardCount: '${_stats.cards}',
      MetaKeys.printCount: '${_stats.prints}',
      MetaKeys.lastCheckAt: now,
      if (bulkUpdatedAt != null) MetaKeys.bulkUpdatedAt: bulkUpdatedAt,
      if (rulingsUpdatedAt != null) MetaKeys.rulingsUpdatedAt: rulingsUpdatedAt,
      if (setsCardTotal != null) MetaKeys.setsCardTotal: '$setsCardTotal',
    };
    await db.batch((b) => b.insertAll(
        db.meta,
        [
          for (final e in entries.entries)
            MetaCompanion.insert(key: e.key, value: e.value)
        ],
        mode: InsertMode.insertOrReplace));
  }
}
