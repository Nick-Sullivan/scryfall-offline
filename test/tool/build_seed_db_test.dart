import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/sync/ingestor.dart';

import '../helpers/test_db.dart';

// Throwaway emulator-seeding helper (see .claude/skills/verify): builds a
// small card DB from the fixtures at BUILD_SEED_DB, e.g.
//   flutter test test/tool/build_seed_db_test.dart --dart-define… (env var)
void main() {
  configureSqliteForTests();

  test('build seed db', () async {
    final out = Platform.environment['BUILD_SEED_DB'];
    if (out == null) {
      markTestSkipped('set BUILD_SEED_DB=<path> to build a seed database');
      return;
    }
    final file = File(out);
    if (file.existsSync()) file.deleteSync();
    final db = AppDatabase.local(file: file);
    final ingestor = Ingestor(db);
    await ingestor.ingestCards(File('test/fixtures/cards_fixture.jsonl')
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(const BulkLineDecoder()));
    await ingestor.finalize(bulkUpdatedAt: '2026-07-17T00:00:00Z');
    await db.close();
    expect(file.existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
