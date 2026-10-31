import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('toggle saves the printing newest-first, removes on second toggle, '
      'persists', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();
    final notifier = container.read(savedCardsProvider.notifier);

    notifier.toggle('aaa', 'a1', preferred: true);
    notifier.toggle('bbb', 'b1', preferred: true);
    expect(container.read(savedCardsProvider), [
      (oracleId: 'bbb', printId: 'b1'),
      (oracleId: 'aaa', printId: 'a1'),
    ]);

    notifier.toggle('aaa', 'a1', preferred: true);
    expect(container.read(savedCardsProvider), [
      (oracleId: 'bbb', printId: 'b1'),
    ]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('savedCards'), ['bbb:b1']);
  });

  test('each printing of a card is saved separately', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();
    final notifier = container.read(savedCardsProvider.notifier);

    notifier.toggle('bolt', 'clb', preferred: true);
    notifier.toggle('bolt', 'm10', preferred: false);
    expect(container.read(savedCardsProvider), hasLength(2));
    expect(notifier.isSaved('bolt', 'm10', preferred: false), isTrue);
    expect(notifier.isSaved('bolt', '2xm', preferred: false), isFalse);

    notifier.toggle('bolt', 'm10', preferred: false);
    expect(container.read(savedCardsProvider), [
      (oracleId: 'bolt', printId: 'clb'),
    ]);
  });

  test('entries saved before printings stand for the preferred one', () async {
    SharedPreferences.setMockInitialValues({
      'savedCards': ['bolt', 'ring:r1'],
    });
    final container = await makeContainer();
    final notifier = container.read(savedCardsProvider.notifier);
    expect(container.read(savedCardsProvider), [
      (oracleId: 'bolt', printId: null),
      (oracleId: 'ring', printId: 'r1'),
    ]);

    expect(notifier.isSaved('bolt', 'clb', preferred: true), isTrue);
    expect(notifier.isSaved('bolt', 'm10', preferred: false), isFalse);

    // Toggling the preferred printing unsaves the legacy entry.
    notifier.toggle('bolt', 'clb', preferred: true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('savedCards'), ['ring:r1']);
  });

  test('clear empties the list', () async {
    SharedPreferences.setMockInitialValues({
      'savedCards': ['x', 'y:y1'],
    });
    final container = await makeContainer();
    container.read(savedCardsProvider.notifier).clear();
    expect(container.read(savedCardsProvider), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('savedCards'), isEmpty);
  });
}
