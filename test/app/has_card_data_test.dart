import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:scryfall_app/app/providers.dart';
import 'package:scryfall_app/data/db/db_files.dart';

/// The router redirects on [hasCardDataProvider]; it must not flicker false
/// while the DB is briefly closed, or an update bounces the user to search.
/// The DB files are placeholders: background connections open lazily, and
/// nothing here queries them.
void main() {
  late Directory temp;
  late DbFiles files;
  late ProviderContainer container;
  late List<bool> seen;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('scryfall_has_data_test');
    files = DbFiles(Directory(p.join(temp.path, 'db')))
      ..root.createSync(recursive: true);
    files.live.writeAsStringSync('placeholder');
    container =
        ProviderContainer(overrides: [dbFilesProvider.overrideWithValue(files)]);
    container.read(databaseProvider);
    seen = [];
    container.listen(hasCardDataProvider, (_, next) => seen.add(next));
  });

  tearDown(() async {
    container.dispose();
    temp.deleteSync(recursive: true);
  });

  test('starts true when card data is installed', () {
    expect(container.read(hasCardDataProvider), isTrue);
  });

  test('stays true through an update swap', () async {
    files.staging.writeAsStringSync('placeholder');
    await container.read(databaseProvider.notifier).swapInStaging();

    expect(seen, isNot(contains(false)));
    expect(container.read(hasCardDataProvider), isTrue);
  });

  test('stays true through a tag-pack reopen', () async {
    await container.read(databaseProvider.notifier).reopen();

    expect(seen, isNot(contains(false)));
    expect(container.read(hasCardDataProvider), isTrue);
  });

  test('turns false when card data is deleted', () async {
    await container.read(databaseProvider.notifier).purge();

    expect(container.read(hasCardDataProvider), isFalse);
  });
}
