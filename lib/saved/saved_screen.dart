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
    final ids = ref.watch(savedCardsProvider);
    final cards = ref.watch(savedCardSummariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved cards'),
        actions: [
          if (ids.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: ids.isEmpty
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
          : cards.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (items) => GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  childAspectRatio: 488 / 680,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final card = items[i];
                  return CardTile(
                    card: card,
                    onRemove: () => ref
                        .read(savedCardsProvider.notifier)
                        .remove(card.oracleId),
                  );
                },
              ),
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
