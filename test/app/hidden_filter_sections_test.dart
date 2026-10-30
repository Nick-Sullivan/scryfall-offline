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

  test('shows only the core sections by default', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();

    final hidden = container.read(hiddenFilterSectionsProvider);
    expect(
        {for (final s in FilterSection.values) if (!hidden.contains(s)) s}, {
      FilterSection.name,
      FilterSection.types,
      FilterSection.rulesText,
      FilterSection.colors,
      FilterSection.identity,
      FilterSection.sort,
    });
  });

  test('hiding and re-showing persists by section name', () async {
    SharedPreferences.setMockInitialValues({'hiddenFilterSections': <String>[]});
    final container = await makeContainer();
    final notifier = container.read(hiddenFilterSectionsProvider.notifier);

    notifier.setVisible(FilterSection.rarity, false);
    notifier.setVisible(FilterSection.artTags, false);
    expect(container.read(hiddenFilterSectionsProvider),
        {FilterSection.rarity, FilterSection.artTags});

    notifier.setVisible(FilterSection.rarity, true);
    expect(container.read(hiddenFilterSectionsProvider),
        {FilterSection.artTags});

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('hiddenFilterSections'), ['artTags']);
  });

  test('an empty saved list means everything shown', () async {
    SharedPreferences.setMockInitialValues({'hiddenFilterSections': <String>[]});
    final container = await makeContainer();

    expect(container.read(hiddenFilterSectionsProvider), isEmpty);
  });

  test('loads persisted sections, dropping unknown names', () async {
    SharedPreferences.setMockInitialValues({
      'hiddenFilterSections': ['power', 'retiredSection', 'sort'],
    });
    final container = await makeContainer();

    expect(container.read(hiddenFilterSectionsProvider),
        {FilterSection.power, FilterSection.sort});
  });
}
