import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/app/providers.dart';
import 'package:scryfall_app/search/ui/card_tile.dart';
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

  test('defaults to medium, which keeps the pre-setting grid width', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();

    expect(container.read(cardSizeProvider), CardSize.medium);
    expect(container.read(cardSizeProvider).maxExtent, 190);
  });

  test('set updates state and persists the name', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();

    container.read(cardSizeProvider.notifier).set(CardSize.large);
    expect(container.read(cardSizeProvider), CardSize.large);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cardSize'), 'large');
  });

  test('loads a persisted choice', () async {
    SharedPreferences.setMockInitialValues({'cardSize': 'small'});
    final container = await makeContainer();

    expect(container.read(cardSizeProvider), CardSize.small);
  });

  test('falls back to medium on an unknown stored value', () async {
    SharedPreferences.setMockInitialValues({'cardSize': 'huge'});
    final container = await makeContainer();

    expect(container.read(cardSizeProvider), CardSize.medium);
  });

  // The grid delegate rounds up to a whole column count, so presets that are
  // merely different numbers can still lay out identically — 280 vs 190 both
  // give two columns on a phone, and the setting looks broken. Pin the actual
  // layout across the phone widths we ship to.
  group('each preset lays out a distinct column count', () {
    int columnsFor(CardSize size, double screenWidth) {
      // The grids pad 8 on each side (see the GridView padding).
      final layout = cardGridDelegate(size.maxExtent).getLayout(
        SliverConstraints(
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          userScrollDirection: ScrollDirection.idle,
          scrollOffset: 0,
          precedingScrollExtent: 0,
          overlap: 0,
          remainingPaintExtent: 800,
          crossAxisExtent: screenWidth - 16,
          crossAxisDirection: AxisDirection.right,
          viewportMainAxisExtent: 800,
          remainingCacheExtent: 800,
          cacheOrigin: 0,
        ),
      );
      // First index on the second row == the number of columns.
      var i = 0;
      while (layout.getGeometryForChildIndex(i).crossAxisOffset > 0 || i == 0) {
        i++;
      }
      return i;
    }

    // 360 = small Android, 393 = Pixel, 412 = large/plus phones.
    for (final width in [360.0, 393.0, 412.0]) {
      test('at ${width.round()}dp wide', () {
        expect(columnsFor(CardSize.small, width), 3);
        expect(columnsFor(CardSize.medium, width), 2);
        expect(columnsFor(CardSize.large, width), 1);
      });
    }
  });
}
