import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/images/art_saver.dart';
import '../search/ui/filter_form.dart';

/// App preferences. Card size applies to both results grids; the default
/// filter — what the app opens with and what the filter panel's Reset returns
/// to — lives in its own collapsible section. Everything saves immediately.
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
    final theme = Theme.of(context);
    final columns = ref.watch(cardColumnsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cards per row', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'How many cards fit across the search and saved grids.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  // Without this the check icon widens whichever segment is
                  // selected, and since every segment matches the widest one
                  // the whole control resizes as you toggle. The selected
                  // segment is already obvious from its fill.
                  showSelectedIcon: false,
                  segments: [
                    for (final n in cardColumnOptions)
                      ButtonSegment(value: n, label: Text('$n')),
                  ],
                  selected: {columns},
                  onSelectionChanged: (s) =>
                      ref.read(cardColumnsProvider.notifier).set(s.first),
                ),
              ],
            ),
          ),
          const Divider(height: 40),
          // iOS saves art to a Photos album, so there's no folder to choose.
          if (Platform.isAndroid) ...[
            ListTile(
              title: const Text('Art download folder'),
              subtitle: Text(switch (ref.watch(artFolderProvider)) {
                final folder? => artFolderPath(folder),
                null => 'Ask on first download',
              }),
              trailing: const Icon(Icons.folder_open),
              onTap: () => ref.read(artFolderProvider.notifier).pick(),
            ),
            const Divider(height: 24),
          ],
          // The Clear action lives inside this section, not the app bar, so it
          // reads as "clear the filter" rather than "reset all settings".
          ExpansionTile(
            title: const Text('Default filter'),
            subtitle: const Text(
                'Applied when the app opens and when you reset the filters.'),
            childrenPadding: EdgeInsets.zero,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () => _set(ref, const FilterState()),
                    child: const Text('Clear'),
                  ),
                ),
              ),
              FilterForm(
                value: ref.watch(defaultFilterProvider),
                onChanged: (next) => _set(ref, next),
                embedded: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
