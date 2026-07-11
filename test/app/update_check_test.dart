import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scryfall_app/app/providers.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/db/tables.dart';
import 'package:scryfall_app/data/repo/card_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  configureSqliteForTests();

  late AppDatabase db;
  late CardRepository repo;
  var requests = 0;
  var serverTotal = 100;

  setUp(() {
    db = AppDatabase.local();
    repo = CardRepository(db);
    requests = 0;
    serverTotal = 100;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => db.close());

  http.Client setsClient() => MockClient((req) async {
        requests++;
        return http.Response(
            jsonEncode({
              'has_more': false,
              'data': [
                {'card_count': serverTotal},
              ],
            }),
            200);
      });

  http.Client offlineClient() =>
      MockClient((req) async => throw http.ClientException('offline'));

  Future<ProviderContainer> makeContainer({http.Client? client}) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      appVersionProvider.overrideWithValue('test'),
      httpClientProvider.overrideWithValue(client ?? setsClient()),
      cardRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('updateCheckProvider (data screen)', () {
    test('no database yet -> true without touching the network', () async {
      final container = await makeContainer();
      container.listen(updateCheckProvider, (_, __) {});
      expect(await container.read(updateCheckProvider.future), isTrue);
      expect(requests, 0);
    });

    test('stored total matches server -> false', () async {
      await repo.setMetaEntry(MetaKeys.setsCardTotal, '100');
      final container = await makeContainer();
      container.listen(updateCheckProvider, (_, __) {});
      expect(await container.read(updateCheckProvider.future), isFalse);
      expect(requests, 1);
    });

    test('server has more cards -> true', () async {
      await repo.setMetaEntry(MetaKeys.setsCardTotal, '100');
      serverTotal = 105;
      final container = await makeContainer();
      container.listen(updateCheckProvider, (_, __) {});
      expect(await container.read(updateCheckProvider.future), isTrue);
    });

    test('offline with no cached total -> null', () async {
      await repo.setMetaEntry(MetaKeys.setsCardTotal, '100');
      final container = await makeContainer(client: offlineClient());
      container.listen(updateCheckProvider, (_, __) {});
      expect(await container.read(updateCheckProvider.future), isNull);
    });

    test('pre-existing install without stored total is seeded, no prompt',
        () async {
      await repo.setMetaEntry(MetaKeys.cardCount, '31000'); // old-style meta
      final container = await makeContainer();
      container.listen(updateCheckProvider, (_, __) {});
      expect(await container.read(updateCheckProvider.future), isFalse);
      expect((await repo.metaEntries())[MetaKeys.setsCardTotal], '100');
    });
  });

  group('updateAvailableProvider (search banner)', () {
    test('fresh cached check inside 24h is reused — zero network calls',
        () async {
      await repo.setMetaEntry(MetaKeys.setsCardTotal, '100');
      SharedPreferences.setMockInitialValues({
        UpdatePrefs.checkTotal: 105,
        UpdatePrefs.checkAt: DateTime.now().toUtc().toIso8601String(),
      });
      final container = await makeContainer();
      expect(await container.read(updateAvailableProvider.future), isTrue);
      expect(requests, 0);
    });

    test('dismiss hides the banner; a different total re-shows it', () async {
      await repo.setMetaEntry(MetaKeys.setsCardTotal, '100');
      SharedPreferences.setMockInitialValues({
        UpdatePrefs.checkTotal: 105,
        UpdatePrefs.checkAt: DateTime.now().toUtc().toIso8601String(),
      });
      final container = await makeContainer();
      expect(await container.read(updateAvailableProvider.future), isTrue);

      container.read(dismissedUpdateProvider.notifier).dismiss(105);
      expect(await container.read(updateAvailableProvider.future), isFalse);

      // Upstream grows again: cache expires, server reports a new total.
      serverTotal = 110;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          UpdatePrefs.checkAt,
          DateTime.now()
              .toUtc()
              .subtract(const Duration(days: 2))
              .toIso8601String());
      container.invalidate(updateAvailableProvider);
      expect(await container.read(updateAvailableProvider.future), isTrue);
    });

    test('dismissal persists across containers (app restarts)', () async {
      await repo.setMetaEntry(MetaKeys.setsCardTotal, '100');
      SharedPreferences.setMockInitialValues({
        UpdatePrefs.checkTotal: 105,
        UpdatePrefs.checkAt: DateTime.now().toUtc().toIso8601String(),
        UpdatePrefs.dismissedTotal: 105,
      });
      final container = await makeContainer();
      expect(await container.read(updateAvailableProvider.future), isFalse);
    });

    test('offline with nothing cached -> false, never blocks the app',
        () async {
      await repo.setMetaEntry(MetaKeys.setsCardTotal, '100');
      final container = await makeContainer(client: offlineClient());
      expect(await container.read(updateAvailableProvider.future), isFalse);
    });
  });
}
