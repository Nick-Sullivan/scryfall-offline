import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../search/ui/card_tile.dart';

/// Cards the user bookmarked, newest first. Each tile has a ✕ to remove it;
/// Clear all (with confirm) empties the list.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedCardsProvider);
    final cards = ref.watch(savedCardSummariesProvider);
    final columns = ref.watch(cardColumnsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved cards'),
        actions: [
          if (saved.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: saved.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No saved cards yet.\n\nTap the bookmark on a card page '
                  'to save it for later.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          // Removing a card re-runs the summaries query. Keep showing the
          // previous results meanwhile (minus anything just removed) so the
          // grid stays mounted and keeps its scroll position.
          : cards.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (items) {
                final visible = items
                    .where((e) => saved.contains(e.$1))
                    .toList();
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: cardGridDelegate(columns),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final (entry, card) = visible[i];
                    return CardTile(
                      key: ValueKey(entry),
                      card: card,
                      onRemove: () =>
                          ref.read(savedCardsProvider.notifier).remove(entry),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear saved cards?'),
        content: const Text('This removes every card from the saved list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(savedCardsProvider.notifier).clear();
    }
  }
}
