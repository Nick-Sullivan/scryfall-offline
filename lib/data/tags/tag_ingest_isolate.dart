import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:sqlite3/open.dart' as sqlite_open;

import '../sync/bulk_line_decoder.dart';
import 'tag_database.dart';
import 'tag_ingestor.dart';

class TagIngestRequest {
  final SendPort progressPort;
  final String stagingDbPath;
  final String tagsPath;
  final bool tagsGzip;
  final String? bulkUpdatedAt;

  /// Desktop-only: sqlite library to load in this isolate (overrides are
  /// per-isolate). Null on mobile, where the bundled library resolves.
  final String? sqliteOverridePath;

  const TagIngestRequest({
    required this.progressPort,
    required this.stagingDbPath,
    required this.tagsPath,
    required this.tagsGzip,
    this.bulkUpdatedAt,
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

/// Isolate entry point: builds the staging tag database from the downloaded
/// `oracle_tags` bulk file. Posts progress maps and finally {'type': 'done'}
/// / {'type': 'error'} on [TagIngestRequest.progressPort].
Future<void> tagIngestIsolateMain(TagIngestRequest req) async {
  final port = req.progressPort;
  TagDatabase? db;
  try {
    final overridePath = req.sqliteOverridePath;
    if (overridePath != null) {
      sqlite_open.open.overrideForAll(() => DynamicLibrary.open(overridePath));
    }
    final stagingFile = File(req.stagingDbPath);
    if (stagingFile.existsSync()) stagingFile.deleteSync();
    stagingFile.parent.createSync(recursive: true);

    db = TagDatabase.local(file: stagingFile, staging: true);
    final ingestor = TagIngestor(db, onProgress: (n) {
      port.send({'type': 'tags', 'n': n});
    });

    await ingestor.ingestTags(_decode(req.tagsPath, req.tagsGzip));
    port.send({'type': 'finalizing'});
    await ingestor.finalize(bulkUpdatedAt: req.bulkUpdatedAt);
    await db.close();
    db = null;
    port.send({
      'type': 'done',
      'tags': ingestor.stats.tags,
      'taggings': ingestor.stats.taggings,
    });
  } catch (e, st) {
    try {
      await db?.close();
    } catch (_) {}
    port.send({'type': 'error', 'message': '$e\n$st'});
  }
}
