import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../about/attribution_screen.dart';
import '../card_detail/ui/detail_screen.dart';
import '../search/ui/search_screen.dart';
import '../sync_ui/onboarding_screen.dart';
import '../sync_ui/update_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final hasData = ValueNotifier(ref.read(databaseProvider) != null);
  ref
    ..listen(databaseProvider, (_, db) => hasData.value = db != null)
    ..onDispose(hasData.dispose);

  return GoRouter(
    refreshListenable: hasData,
    initialLocation: '/',
    redirect: (context, state) {
      final onboarding = state.matchedLocation == '/onboarding';
      if (!hasData.value && !onboarding) return '/onboarding';
      if (hasData.value && onboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/', builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: '/card/:oracleId',
        builder: (_, state) => DetailScreen(
          oracleId: state.pathParameters['oracleId']!,
          printId: state.uri.queryParameters['print'],
        ),
      ),
      GoRoute(path: '/data', builder: (_, __) => const UpdateScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AttributionScreen()),
    ],
  );
});
