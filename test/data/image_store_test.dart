import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:scryfall_app/app/providers.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/images/image_store.dart';
import 'package:scryfall_app/data/repo/card_repository.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/sync/ingestor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  configureSqliteForTests();

  late Directory tmp;
  late ImageStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('image_store_test');
    store = ImageStore(Directory(p.join(tmp.path, 'images')))
      ..root.createSync();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  void put(String name, [String body = 'x']) =>
      File(p.join(store.root.path, name)).writeAsStringSync(body);
  String? read(String name) {
    final f = File(p.join(store.root.path, name));
    return f.existsSync() ? f.readAsStringSync() : null;
  }

  group('fileFor', () {
    test('prefers the print file, falling back to a legacy one', () {
      put('oracle.jpg');
      expect(p.basename(store.fileFor('print').path), 'print.jpg');
      expect(
        p.basename(store.fileFor('print', legacyOracleId: 'oracle').path),
        'oracle.jpg',
      );
      put('print.jpg');
      expect(
        p.basename(store.fileFor('print', legacyOracleId: 'oracle').path),
        'print.jpg',
      );
    });
  });

  group('migrate', () {
    test('renames mapped files and keeps everything else', () async {
      put('o1.jpg', 'one');
      put('o2.jpg', 'two-legacy');
      put('p2.jpg', 'two'); // already downloaded under its print id
      put('gone.jpg'); // card no longer in the data
      put('o3.jpg.part');
      await store.migrate({'o1': 'p1', 'o2': 'p2', 'o3': 'p3'});
      expect(read('p1.jpg'), 'one');
      expect(read('o1.jpg'), isNull);
      expect(read('p2.jpg'), 'two');
      expect(read('o2.jpg'), isNull);
      expect(read('gone.jpg'), 'x');
      expect(read('o3.jpg.part'), 'x');
      expect(read('p3.jpg'), isNull);
    });

    test('a second run finishes an interrupted one', () async {
      put('o1.jpg', 'one');
      put('p2.jpg', 'two'); // renamed before the interruption
      put('o3.jpg', 'three');
      final mapping = {'o1': 'p1', 'o2': 'p2', 'o3': 'p3'};
      await store.migrate(mapping);
      await store.migrate(mapping);
      expect(await store.storedIds(), {'p1', 'p2', 'p3'});
    });
  });

  group('imageMigrationProvider', () {
    late AppDatabase db;
    late CardRepository repo;

    setUp(() async {
      db = AppDatabase.local();
      final ingestor = Ingestor(db);
      await ingestor.ingestCards(
        File('test/fixtures/cards_fixture.jsonl')
            .openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .transform(const BulkLineDecoder()),
      );
      await ingestor.finalize();
      repo = CardRepository(db);
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() => db.close());

    Future<ProviderContainer> container({CardRepository? repo}) async {
      final c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
          imageStoreProvider.overrideWithValue(store),
          cardRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('upgrades an oracle-keyed pack without losing images', () async {
      final mapping = await repo.preferredPrintIds();
      for (final oracleId in mapping.keys) {
        put('$oracleId.jpg');
      }
      final c = await container(repo: repo);
      final status = await c.read(imagePackStatusProvider.future);
      expect(status.downloaded, mapping.length);
      expect(status.cardMissing, 0);
      expect(status.printMissing, 1); // Bolt's other printing
      expect(await store.storedIds(), mapping.values.toSet());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('imagesKeyedByPrint'), isTrue);
    });

    test('waits for card data rather than guessing', () async {
      put('some-oracle-id.jpg');
      final c = await container();
      await c.read(imageMigrationProvider.future);
      expect(await store.storedIds(), {'some-oracle-id'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('imagesKeyedByPrint'), isNull);
    });

    test('an empty store needs no migration', () async {
      final c = await container();
      await c.read(imageMigrationProvider.future);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('imagesKeyedByPrint'), isTrue);
    });
  });
}
