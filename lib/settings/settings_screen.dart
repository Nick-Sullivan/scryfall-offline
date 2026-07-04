import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../search/ui/filter_form.dart';

/// Edits the persisted default filter — what the app opens with and what the
/// filter panel's Reset returns to. Changes save and apply immediately.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _set(WidgetRef ref, FilterState next) {
    ref.read(defaultFilterProvider.notifier).set(next);
    // The active filter follows the default automatically; re-run the search
    // so the results behind this screen match when the user goes back.
    ref.read(searchProvider.notifier).setQuery(next.toSyntax());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: () => _set(ref, const FilterState()),
            child: const Text('Clear'),
          ),
        ],
      ),
      body: FilterForm(
        value: ref.watch(defaultFilterProvider),
        onChanged: (next) => _set(ref, next),
        header: [
          const SizedBox(height: 12),
          Text('Default filter',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Applied when the app opens and when you reset the filters.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
