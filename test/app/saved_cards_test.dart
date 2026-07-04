import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/app/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final container =
        ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    return container;
  }

  test('toggle saves newest-first, removes on second toggle, persists',
      () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();
    final notifier = container.read(savedCardsProvider.notifier);

    notifier.toggle('aaa');
    notifier.toggle('bbb');
    expect(container.read(savedCardsProvider), ['bbb', 'aaa']);

    notifier.toggle('aaa');
    expect(container.read(savedCardsProvider), ['bbb']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('savedCards'), ['bbb']);
  });

  test('loads persisted list and clear empties it', () async {
    SharedPreferences.setMockInitialValues({
      'savedCards': ['x', 'y'],
    });
    final container = await makeContainer();
    expect(container.read(savedCardsProvider), ['x', 'y']);

    container.read(savedCardsProvider.notifier).clear();
    expect(container.read(savedCardsProvider), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('savedCards'), isEmpty);
  });
}
