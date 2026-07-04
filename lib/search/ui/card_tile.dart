import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../data/repo/card_repository.dart';

/// One card in a results grid. Prefers the offline image pack, then the
/// 'normal' network image, with a text tile underneath while loading and as
/// the no-image fallback. [onRemove] adds a small ✕ badge (saved-cards grid).
class CardTile extends ConsumerWidget {
  final CardSummary card;
  final VoidCallback? onRemove;

  const CardTile({super.key, required this.card, this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = ref.watch(imageStoreProvider).fileFor(card.oracleId);
    final url = card.imageNormal ?? card.imageSmall;
    final Widget image;
    if (local.existsSync()) {
      image = Image.file(
        local,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CardTextFallback(card: card),
      );
    } else if (url == null) {
      image = CardTextFallback(card: card);
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, __) => Stack(
          fit: StackFit.expand,
          children: [
            CardTextFallback(card: card),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
        errorWidget: (_, __, ___) => CardTextFallback(card: card),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            onTap: () => context.push('/card/${card.oracleId}'),
            borderRadius: BorderRadius.circular(9),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: image,
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CardTextFallback extends StatelessWidget {
  final CardSummary card;

  const CardTextFallback({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            card.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (card.manaCost != null)
            Text(card.manaCost!, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(
            card.typeLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
