import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:sqlite3/open.dart' as sqlite_open;

import '../db/database.dart';
import 'bulk_line_decoder.dart';
import 'ingestor.dart';

class IngestRequest {
  final SendPort progressPort;
  final String stagingDbPath;
  final String cardsPath;
  final bool cardsGzip;
  final String? rulingsPath;
  final bool rulingsGzip;
  final String? bulkUpdatedAt;
  final String? rulingsUpdatedAt;
  final int? setsCardTotal;

  /// Desktop-only: sqlite library to load in this isolate (overrides are
  /// per-isolate). Null on mobile, where the bundled library resolves.
  final String? sqliteOverridePath;

  const IngestRequest({
    required this.progressPort,
    required this.stagingDbPath,
    required this.cardsPath,
    required this.cardsGzip,
    this.rulingsPath,
    this.rulingsGzip = true,
    this.bulkUpdatedAt,
    this.rulingsUpdatedAt,
    this.setsCardTotal,
    this.sqliteOverridePath,
  });
}

Stream<Map<String, dynamic>> _decode(String path, bool isGzip) {
  Stream<List<int>> bytes = File(path).openRead();
  if (isGzip) bytes = bytes.transform(gzip.decoder);
  return bytes
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .transform(const BulkLineDecoder());
}

/// Isolate entry point: builds the staging database from downloaded bulk
/// files. Posts progress maps and finally {'type': 'done'} / {'type':
/// 'error'} on [IngestRequest.progressPort].
Future<void> ingestIsolateMain(IngestRequest req) async {
  final port = req.progressPort;
  AppDatabase? db;
  try {
    final overridePath = req.sqliteOverridePath;
    if (overridePath != null) {
      sqlite_open.open
          .overrideForAll(() => DynamicLibrary.open(overridePath));
    }
    final stagingFile = File(req.stagingDbPath);
    if (stagingFile.existsSync()) stagingFile.deleteSync();
    stagingFile.parent.createSync(recursive: true);

    db = AppDatabase.local(file: stagingFile, staging: true);
    final ingestor = Ingestor(db, onProgress: (n) {
      port.send({'type': 'cards', 'n': n});
    });

    await ingestor.ingestCards(_decode(req.cardsPath, req.cardsGzip));
    if (req.rulingsPath != null) {
      port.send({'type': 'rulings', 'n': 0});
      await ingestor.ingestRulings(_decode(req.rulingsPath!, req.rulingsGzip));
    }
    port.send({'type': 'finalizing'});
    await ingestor.finalize(
      bulkUpdatedAt: req.bulkUpdatedAt,
      rulingsUpdatedAt: req.rulingsUpdatedAt,
      setsCardTotal: req.setsCardTotal,
    );
    await db.close();
    db = null;
    port.send({
      'type': 'done',
      'cards': ingestor.stats.cards,
      'prints': ingestor.stats.prints,
    });
  } catch (e, st) {
    try {
      await db?.close();
    } catch (_) {}
    port.send({'type': 'error', 'message': '$e\n$st'});
  }
}
