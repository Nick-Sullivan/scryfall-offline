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
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to the pre-setting column count', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();

    expect(container.read(cardColumnsProvider), 2);
  });

  test('set updates state and persists the count', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer();

    container.read(cardColumnsProvider.notifier).set(4);
    expect(container.read(cardColumnsProvider), 4);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('cardColumns'), 4);
  });

  test('loads a persisted count', () async {
    SharedPreferences.setMockInitialValues({'cardColumns': 3});
    final container = await makeContainer();

    expect(container.read(cardColumnsProvider), 3);
  });

  // A zero would divide by zero laying out the grid, so out-of-range values
  // have to fall back rather than reach the delegate.
  for (final bad in [0, -1, 99]) {
    test('falls back to the default on an out-of-range value ($bad)', () async {
      SharedPreferences.setMockInitialValues({'cardColumns': bad});
      final container = await makeContainer();

      expect(container.read(cardColumnsProvider), 2);
    });
  }

  test('the grid delegate lays out exactly the requested columns', () {
    int columnsOf(int requested) {
      final layout = cardGridDelegate(requested).getLayout(
        const SliverConstraints(
          axisDirection: AxisDirection.down,
          growthDirection: GrowthDirection.forward,
          userScrollDirection: ScrollDirection.idle,
          scrollOffset: 0,
          precedingScrollExtent: 0,
          overlap: 0,
          remainingPaintExtent: 800,
          crossAxisExtent: 377, // a Pixel-width viewport, less grid padding
          crossAxisDirection: AxisDirection.right,
          viewportMainAxisExtent: 800,
          remainingCacheExtent: 800,
          cacheOrigin: 0,
        ),
      );
      // The first index back at offset 0 starts the second row.
      var i = 0;
      while (layout.getGeometryForChildIndex(i).crossAxisOffset > 0 || i == 0) {
        i++;
      }
      return i;
    }

    for (final n in cardColumnOptions) {
      expect(columnsOf(n), n, reason: '$n columns requested');
    }
  });
}
