import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/db/db_files.dart';
import 'package:scryfall_app/data/sync/ingest_isolate.dart';

import '../helpers/test_db.dart';

void main() {
  configureSqliteForTests();

  late Directory temp;
  late DbFiles files;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('scryfall_sync_test');
    files = DbFiles(Directory(p.join(temp.path, 'db')))
      ..root.createSync(recursive: true);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  File gzipFixture(String source, String name) {
    final out = File(p.join(temp.path, name));
    out.writeAsBytesSync(gzip.encode(File(source).readAsBytesSync()));
    return out;
  }

  test('ingest isolate builds staging DB, swap makes it live', () async {
    final cardsGz =
        gzipFixture('test/fixtures/cards_fixture.jsonl', 'cards.jsonl.gz');
    final rulingsGz =
        gzipFixture('test/fixtures/rulings_fixture.jsonl', 'rulings.jsonl.gz');

    final port = ReceivePort();
    final done = Completer<Map>();
    final phases = <String>[];
    port.listen((msg) {
      final map = msg as Map;
      phases.add(map['type'] as String);
      if (map['type'] == 'done' || map['type'] == 'error') done.complete(map);
    });

    final dllPath =
        File('tools/sqlite3/sqlite3.dll').absolute.path;
    await Isolate.spawn(
      ingestIsolateMain,
      IngestRequest(
        progressPort: port.sendPort,
        stagingDbPath: files.staging.path,
        cardsPath: cardsGz.path,
        cardsGzip: true,
        rulingsPath: rulingsGz.path,
        rulingsGzip: true,
        bulkUpdatedAt: '2026-07-03T00:00:00Z',
        setsCardTotal: 12345,
        sqliteOverridePath: Platform.isWindows ? dllPath : null,
      ),
    );

    final result = await done.future.timeout(const Duration(minutes: 2));
    port.close();
    expect(result['type'], 'done',
        reason: 'isolate reported: ${result['message']}');
    expect(result['cards'], 16);
    expect(result['prints'], 17);
    expect(phases, contains('finalizing'));
    expect(files.staging.existsSync(), isTrue);
    expect(files.hasLiveDatabase, isFalse);

    // Atomic swap, then the live DB answers queries.
    files.swapStagingIntoLive();
    expect(files.hasLiveDatabase, isTrue);
    expect(files.staging.existsSync(), isFalse);

    final db = AppDatabase.local(file: files.live);
    final row = await db
        .customSelect('SELECT COUNT(*) AS n FROM cards')
        .getSingle();
    expect(row.data['n'], 16);
    final meta = await db
        .customSelect(
            "SELECT value FROM meta WHERE key = 'bulkUpdatedAt'")
        .getSingle();
    expect(meta.data['value'], '2026-07-03T00:00:00Z');
    final setsTotal = await db
        .customSelect("SELECT value FROM meta WHERE key = 'setsCardTotal'")
        .getSingle();
    expect(setsTotal.data['value'], '12345');
    await db.close();
  });

  test('cleanupStray removes leftovers from interrupted syncs', () {
    files.staging.writeAsStringSync('junk');
    files.old.writeAsStringSync('junk');
    files.cleanupStray();
    expect(files.staging.existsSync(), isFalse);
    expect(files.old.existsSync(), isFalse);
  });
}
