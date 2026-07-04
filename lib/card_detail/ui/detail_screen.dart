import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/legalities.dart';
import '../../data/repo/card_repository.dart';

class DetailScreen extends ConsumerWidget {
  final String oracleId;
  final String? printId;

  const DetailScreen({super.key, required this.oracleId, this.printId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail =
        ref.watch(cardDetailProvider((oracleId: oracleId, printId: printId)));
    // The offline pack stores the preferred print's front image; use it when
    // that's the print being shown.
    final local = printId == null
        ? ref.watch(imageStoreProvider).fileFor(oracleId)
        : null;
    final localFront = (local?.existsSync() ?? false) ? local : null;
    final saved = ref.watch(savedCardsProvider).contains(oracleId);
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.valueOrNull?.name ?? ''),
        actions: [
          IconButton(
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            tooltip: saved ? 'Remove from saved' : 'Save to view later',
            onPressed: () =>
                ref.read(savedCardsProvider.notifier).toggle(oracleId),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load card: $e')),
        data: (card) => card == null
            ? const Center(child: Text('Card not found.'))
            : _DetailBody(card: card, localFront: localFront),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final CardDetail card;
  final File? localFront;

  const _DetailBody({required this.card, this.localFront});

  @override
  Widget build(BuildContext context) {
    final json = card.rawJson;
    final faces =
        (json['card_faces'] as List?)?.cast<Map<String, dynamic>>() ?? [json];
    final pages = _facePages(json, faces);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pages.isNotEmpty)
          _ImagePager(pages: pages, localFirst: localFront),
        _artistLine(context, json, faces),
        const SizedBox(height: 16),
        for (final (i, face) in faces.indexed) ...[
          if (i > 0) const Divider(height: 32),
          _FaceText(face: face),
        ],
        const Divider(height: 32),
        Text('Legalities', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _LegalitiesGrid(packed: card.legalities),
        const Divider(height: 32),
        Text('Printings (${card.printings.length})',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _PrintingsList(card: card),
        if (card.rulings.isNotEmpty) ...[
          const Divider(height: 32),
          Text('Rulings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final r in card.rulings)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.publishedAt,
                      style: Theme.of(context).textTheme.labelSmall),
                  Text(r.comment),
                ],
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// One (image, face) page per face for transform/mdfc; a single shared
  /// image otherwise. The face rides along so a failed image load can show
  /// the right face's text in the card slot instead.
  List<(String, Map<String, dynamic>)> _facePages(
      Map<String, dynamic> json, List<Map<String, dynamic>> faces) {
    final topLevel =
        (json['image_uris'] as Map<String, dynamic>?)?['normal'] as String?;
    if (topLevel != null) return [(topLevel, faces.first)];
    return [
      for (final f in faces)
        if ((f['image_uris'] as Map<String, dynamic>?)?['normal']
            case final String uri)
          (uri, f)
    ];
  }

  /// Fan Content Policy: artist + © stays visible with the card image.
  Widget _artistLine(BuildContext context, Map<String, dynamic> json,
      List<Map<String, dynamic>> faces) {
    final artist = json['artist'] as String? ??
        faces.first['artist'] as String? ??
        'Unknown artist';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Illustrated by $artist — ™ & © Wizards of the Coast',
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ImagePager extends StatefulWidget {
  final List<(String, Map<String, dynamic>)> pages;

  /// Local file for the first face, when the offline pack has it.
  final File? localFirst;

  const _ImagePager({required this.pages, this.localFirst});

  @override
  State<_ImagePager> createState() => _ImagePagerState();
}

class _ImagePagerState extends State<_ImagePager> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    _controller.animateToPage(
      (_page + 1) % widget.pages.length,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 488 / 680,
          child: Stack(
            children: [
              PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final (i, (uri, face)) in widget.pages.indexed)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: i == 0 && widget.localFirst != null
                          ? Image.file(
                              widget.localFirst!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  _TextCardFace(face: face),
                            )
                          : CachedNetworkImage(
                              imageUrl: uri,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator()),
                              // Offline with no image pack — show the card's
                              // text in the card slot instead.
                              errorWidget: (_, __, ___) =>
                                  _TextCardFace(face: face),
                            ),
                    ),
                ],
              ),
              if (widget.pages.length > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: null,
                    tooltip: 'Flip card',
                    onPressed: _flip,
                    child: const Icon(Icons.autorenew),
                  ),
                ),
            ],
          ),
        ),
        if (widget.pages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Face ${_page + 1} of ${widget.pages.length}',
                style: Theme.of(context).textTheme.labelSmall),
          ),
      ],
    );
  }
}

/// A card-shaped text rendition shown in the image slot when the image
/// can't be loaded (offline without the image pack).
class _TextCardFace extends StatelessWidget {
  final Map<String, dynamic> face;

  const _TextCardFace({required this.face});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.dividerColor, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(child: _FaceText(face: face)),
    );
  }
}

class _FaceText extends StatelessWidget {
  final Map<String, dynamic> face;

  const _FaceText({required this.face});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pt = face['power'] != null
        ? '${face['power']}/${face['toughness']}'
        : face['loyalty'] != null
            ? 'Loyalty: ${face['loyalty']}'
            : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(face['name'] as String? ?? '',
                  style: theme.textTheme.titleMedium),
            ),
            Text(face['mana_cost'] as String? ?? '',
                style: theme.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(face['type_line'] as String? ?? '',
            style: theme.textTheme.bodyMedium!
                .copyWith(fontStyle: FontStyle.italic)),
        if ((face['oracle_text'] as String?)?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(face['oracle_text'] as String),
          ),
        if ((face['flavor_text'] as String?)?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(face['flavor_text'] as String,
                style: theme.textTheme.bodySmall!
                    .copyWith(fontStyle: FontStyle.italic)),
          ),
        if (pt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(pt, style: theme.textTheme.titleSmall),
          ),
      ],
    );
  }
}

class _LegalitiesGrid extends StatelessWidget {
  final int packed;

  const _LegalitiesGrid({required this.packed});

  static const _shown = [
    'standard', 'pioneer', 'modern', 'legacy',
    'vintage', 'pauper', 'commander', 'brawl',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final format in _shown) _chip(context, format),
      ],
    );
  }

  Widget _chip(BuildContext context, String format) {
    final status = legalityStatus(packed, format);
    final (label, color) = switch (status) {
      statusLegal => ('Legal', Colors.green),
      statusBanned => ('Banned', Colors.red),
      statusRestricted => ('Restricted', Colors.orange),
      _ => ('Not legal', Colors.grey),
    };
    return SizedBox(
      width: 160,
      child: Row(
        children: [
          Expanded(child: Text(format)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label,
                style: TextStyle(fontSize: 12, color: color.shade700)),
          ),
        ],
      ),
    );
  }
}

class _PrintingsList extends StatelessWidget {
  final CardDetail card;

  const _PrintingsList({required this.card});

  @override
  Widget build(BuildContext context) {
    final currentPrintId = card.rawJson['id'] as String?;
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: card.printings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final print = card.printings[i];
          final selected = print.id == currentPrintId;
          return InkWell(
            onTap: () => context.replace(
                '/card/${card.oracleId}?print=${print.id}'),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(
                  width: selected ? 2 : 1,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: print.imageSmall == null
                        ? const Center(child: Icon(Icons.image_outlined))
                        : CachedNetworkImage(
                            imageUrl: print.imageSmall!,
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${print.setCode.toUpperCase()} #${print.collectorNumber}',
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    print.rarityName,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
