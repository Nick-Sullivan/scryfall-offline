import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/legalities.dart';
import '../../data/images/art_saver.dart';
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

/// Saves every printing's full-card PNG — into the picked folder on Android
/// (asking for one the first time), or a gallery album on iOS. Shows export
/// progress in place of the icon while this card's export runs; tapping it
/// cancels.
class _DownloadArtButton extends ConsumerWidget {
  final String oracleId;

  const _DownloadArtButton({required this.oracleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(artExportProvider, (prev, next) {
      if (prev?.running == true &&
          next != null &&
          !next.running &&
          next.oracleId == oracleId) {
        _showResult(ScaffoldMessenger.of(context), next,
            ref.read(artFolderProvider.notifier));
      }
    });

    final export = ref.watch(artExportProvider);
    if (export != null && export.running) {
      final mine = export.oracleId == oracleId;
      return IconButton(
        tooltip: mine ? 'Cancel art download' : 'Another download is running',
        onPressed:
            mine ? () => ref.read(artExportProvider.notifier).cancel() : null,
        icon: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            value: mine && export.total > 0
                ? (export.done + export.failed) / export.total
                : null,
          ),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.download),
      tooltip: 'Download all art',
      onPressed: () => _confirmAndStart(context, ref),
    );
  }

  /// The done message: an Open action on success, or a way to pick a new
  /// folder when the old one vanished mid-run.
  static void _showResult(ScaffoldMessengerState messenger,
      ArtExportProgress result, ArtFolderNotifier folders) {
    if (result.folderLost) {
      messenger.showSnackBar(SnackBar(
        content: const Text('Lost access to the save folder; choose it again'),
        action: SnackBarAction(label: 'Choose', onPressed: folders.pick),
      ));
      return;
    }
    final failed = result.failed > 0 ? ' (${result.failed} failed)' : '';
    messenger.showSnackBar(SnackBar(
      content: Text(
          'Saved ${result.done} images to ${result.saver.label}$failed'),
      action: SnackBarAction(
        label: 'Open',
        onPressed: () async {
          if (!await result.saver.open()) {
            messenger.showSnackBar(const SnackBar(
                content: Text('No app on this device can open the folder')));
          }
        },
      ),
    ));
  }

  /// Android: the remembered folder, or a fresh pick when there is none or
  /// its grant was revoked. iOS: photo-library access for the album.
  Future<ArtSaver?> _resolveSaver(
      WidgetRef ref, ScaffoldMessengerState messenger) async {
    if (Platform.isAndroid) {
      final folders = ref.read(artFolderProvider.notifier);
      var folder = ref.read(artFolderProvider);
      if (folder == null || !await ArtFolderChannel.hasAccess(folder.uri)) {
        folder = await folders.pick();
      }
      return artSaverFor(folder);
    }
    final allowed = await Gal.hasAccess(toAlbum: true) ||
        await Gal.requestAccess(toAlbum: true);
    if (!allowed) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Photo access is needed to save card images')));
      return null;
    }
    return artSaverFor(null);
  }

  Future<void> _confirmAndStart(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(cardRepositoryProvider);
    if (repo == null) return;

    final saver = await _resolveSaver(ref, messenger);
    if (saver == null) return;

    final targets = await repo.artTargets(oracleId);
    final Set<String> existing;
    try {
      existing = await saver.existingNames();
    } on ArtFolderLostException {
      final folders = ref.read(artFolderProvider.notifier)..clear();
      messenger.showSnackBar(SnackBar(
        content: const Text('Lost access to the save folder; choose it again'),
        action: SnackBarAction(label: 'Choose', onPressed: folders.pick),
      ));
      return;
    }
    if (!context.mounted) return;
    if (targets.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No images available for this card')));
      return;
    }

    final folders = ref.read(artFolderProvider.notifier);
    final chosen = await showDialog<ArtSaver>(
      context: context,
      builder: (context) => _ConfirmArtDialog(
        targets: targets,
        saver: saver,
        existing: existing,
        // Only Android has folders to switch between.
        onChangeFolder: Platform.isAndroid
            ? () async {
                final next = artSaverFor(await folders.pick());
                if (next == null) return null;
                try {
                  return (next, await next.existingNames());
                } on ArtFolderLostException {
                  return (next, const <String>{});
                }
              }
            : null,
      ),
    );
    if (chosen != null) {
      ref.read(artExportProvider.notifier).start(oracleId, targets, chosen);
    }
  }
}

/// Spells out what will be saved (printings vs. images, since double-faced
/// cards save two per printing) and where, with a way to change the folder
/// in place. Pops the [ArtSaver] to use, or null on cancel.
class _ConfirmArtDialog extends StatefulWidget {
  final List<ArtTarget> targets;
  final ArtSaver saver;
  final Set<String> existing;
  final Future<(ArtSaver, Set<String>)?> Function()? onChangeFolder;

  const _ConfirmArtDialog({
    required this.targets,
    required this.saver,
    required this.existing,
    required this.onChangeFolder,
  });

  @override
  State<_ConfirmArtDialog> createState() => _ConfirmArtDialogState();
}

class _ConfirmArtDialogState extends State<_ConfirmArtDialog> {
  late var _saver = widget.saver;
  late var _existing = widget.existing;

  Future<void> _change() async {
    final next = await widget.onChangeFolder!();
    if (next case (final saver, final existing) when mounted) {
      setState(() {
        _saver = saver;
        _existing = existing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = widget.targets;
    final backs = targets.where((t) => t.name.endsWith(' (back)')).length;
    final printings = targets.length - backs;
    final replacing =
        targets.where((t) => _existing.contains('${t.name}.png')).length;

    return AlertDialog(
      title: const Text('Download all art'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$printings ${printings == 1 ? 'printing' : 'printings'}'
              '${backs > 0 ? ', front and back' : ''}'),
          const SizedBox(height: 16),
          Text('Save to folder', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_saver.label, style: theme.textTheme.titleSmall),
              ),
              if (widget.onChangeFolder != null)
                TextButton(onPressed: _change, child: const Text('Change')),
            ],
          ),
          if (replacing > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  '$replacing already in this folder will be replaced.',
                  style: theme.textTheme.bodySmall),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _saver),
          child: const Text('Download'),
        ),
      ],
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
        _OracleTags(oracleId: card.oracleId),
        const Divider(height: 32),
        Text('Legalities', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _LegalitiesGrid(packed: card.legalities),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: Text('Printings (${card.printings.length})',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            _DownloadArtButton(oracleId: card.oracleId),
          ],
        ),
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

/// Oracle tags on this card, each a shortcut into a search for it. Renders
/// nothing when the optional tag pack isn't installed (or the card is
/// untagged), so the section simply doesn't exist without the download.
class _OracleTags extends ConsumerWidget {
  final String oracleId;

  const _OracleTags({required this.oracleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(cardTagsProvider(oracleId)).valueOrNull ?? const [];
    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text('Oracle tags', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (slug, label) in tags)
              ActionChip(
                label: Text(label),
                tooltip: 'Search for otag:$slug',
                onPressed: () => _search(context, ref, slug, label),
              ),
          ],
        ),
      ],
    );
  }

  /// Adds the tag to the active filter — rather than replacing it — so this
  /// composes with whatever the user already had, then returns to the results.
  void _search(BuildContext context, WidgetRef ref, String slug, String label) {
    final next = ref.read(filterProvider).copyWith(
        otags: {...ref.read(filterProvider).otags, slug: label});
    ref.read(filterProvider.notifier).set(next);
    ref.read(searchProvider.notifier).setQuery(next.toSyntax());
    context.go('/');
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
