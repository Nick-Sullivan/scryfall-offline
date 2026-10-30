import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app/providers.dart';
import '../data/sync/sync_progress.dart';
import 'sync_progress_view.dart';

class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(metaProvider).valueOrNull ?? const {};
    final progress = ref.watch(syncControllerProvider);
    final running =
        progress != null && progress is! SyncFailed && progress is! SyncDone;
    final check = ref.watch(updateCheckProvider);
    // true = update exists, false = current, null = offline/unknown.
    final updateAvailable = check.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Card data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _row('Cards', meta['cardCount'] ?? '—'),
          _row('Printings', meta['printCount'] ?? '—'),
          _row('Data from', _friendlyDate(meta['bulkUpdatedAt'])),
          _row(
            'Last update check',
            _friendlyDate(
              ref.watch(prefsProvider).getString(UpdatePrefs.checkAt),
            ),
          ),
          const SizedBox(height: 24),
          if (progress != null) ...[
            SyncProgressView(progress: progress),
            const SizedBox(height: 16),
          ],
          if (check.isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Checking for updates…'),
              ],
            )
          else if (updateAvailable == false)
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                const Text('Your card data is up to date.'),
              ],
            )
          else ...[
            FilledButton.icon(
              onPressed: running
                  ? null
                  : () => ref.read(syncControllerProvider.notifier).start(),
              icon: const Icon(Icons.refresh),
              label: const Text('Download latest card data'),
            ),
            if (updateAvailable == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Couldn\'t reach Scryfall to check whether this is newer '
                'than what you have.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
          const Divider(height: 40),
          const _ImagePackSection(),
          const Divider(height: 40),
          const _TagPackSection(),
          const Divider(height: 40),
          OutlinedButton.icon(
            onPressed: running ? null : () => _confirmPurge(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete downloaded data'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Frees up the ~500 MB card database. You can re-download it any '
            'time; the app will return to the first-time setup screen.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPurge(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete downloaded data?'),
        content: const Text(
          'This removes the local card database. Search will be unavailable '
          'until you download it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(syncControllerProvider.notifier).reset();
    await ref.read(databaseProvider.notifier).purge();
    // databaseProvider is now null → the router redirects to onboarding.
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  String _friendlyDate(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return '—';
    return dt.toLocal().toString().split('.').first;
  }
}

class _ImagePackSection extends ConsumerStatefulWidget {
  const _ImagePackSection();

  @override
  ConsumerState<_ImagePackSection> createState() => _ImagePackSectionState();
}

class _ImagePackSectionState extends ConsumerState<_ImagePackSection> {
  // Measured average for Scryfall 'normal' JPGs.
  static const _avgImageKb = 100;

  /// Download every print's image, not just each card's preferred one.
  bool _allPrints = false;

  String _gb(int images) =>
      '${(images * _avgImageKb / 1024 / 1024).toStringAsFixed(1)} GB';

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(imagePackProvider);
    final running = progress?.running ?? false;
    final status = ref.watch(imagePackStatusProvider).valueOrNull;
    final downloaded = status?.downloaded ?? 0;
    // (set size, still missing) for the chosen set.
    final (total, missing) = switch (status) {
      null => (0, 0),
      final s when _allPrints => (s.printTotal, s.printMissing),
      final s => (s.cardTotal, s.cardMissing),
    };

    // Multi-hour download — keep the screen awake while it runs.
    WakelockPlus.toggle(enable: running);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Offline card images',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              'All printings',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 8),
            Switch(
              value: _allPrints,
              onChanged: running ? null : (v) => setState(() => _allPrints = v),
            ),
          ],
        ),
        if (running && progress != null) ...[
          LinearProgressIndicator(
            value: progress.total == 0 ? null : progress.done / progress.total,
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.done} of ${progress.total} images'
            '${progress.failed > 0 ? ' (${progress.failed} failed)' : ''}',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ref.read(imagePackProvider.notifier).cancel(),
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
          ),
        ] else ...[
          Text(
            (status?.cardTotal ?? 0) == 0
                ? 'No card data yet.'
                : missing == 0
                ? '$total of $total images downloaded '
                      '(${_gb(downloaded)}).'
                : '${total - missing} of $total images downloaded '
                      '(~${_gb(missing)} to go).',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: missing == 0
                    ? null
                    : () => ref
                          .read(imagePackProvider.notifier)
                          .start(allPrints: _allPrints),
                icon: const Icon(Icons.image),
                label: const Text('Download images'),
              ),
              const SizedBox(width: 8),
              if (downloaded > 0)
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(imagePackProvider.notifier).deleteAll();
                    ref.invalidate(imagePackStatusProvider);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete images'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'For fully offline browsing. Stop and resume any time.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class _TagPackSection extends ConsumerWidget {
  const _TagPackSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(tagPackProvider);
    final running = progress?.running ?? false;
    final status = ref.watch(tagPackStatusProvider).valueOrNull;

    String friendlyDate(String? iso) {
      final dt = DateTime.tryParse(iso ?? '');
      return dt == null ? '—' : dt.toLocal().toString().split(' ').first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (running && progress != null) ...[
          LinearProgressIndicator(value: progress.fraction),
          const SizedBox(height: 8),
          Text(progress.label),
        ] else ...[
          Text(switch (status) {
            null => 'Not downloaded.',
            final s =>
              '${s.tags} oracle tags'
                  '${s.artTags == null ? '' : ' and ${s.artTags} art tags'}, '
                  'downloaded ${friendlyDate(s.fetchedAt)}.',
          }),
          // Packs from before art tags have no art tables at all.
          if (status != null && status.artTags == null) ...[
            const SizedBox(height: 4),
            const Text('Re-download to add art tags.'),
          ],
          if (progress?.error != null) ...[
            const SizedBox(height: 4),
            Text(
              'Download failed: ${progress!.error}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: () => ref.read(tagPackProvider.notifier).start(),
                icon: const Icon(Icons.sell_outlined),
                label: Text(
                  status == null ? 'Download tag data (~20 MB)' : 'Re-download',
                ),
              ),
              const SizedBox(width: 8),
              if (status != null)
                OutlinedButton.icon(
                  onPressed: () => ref.read(tagPackProvider.notifier).delete(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete tag data'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Community tags for what a card does (otag:removal) and what its '
          'art shows (atag:dragon).',
          style: TextStyle(fontSize: 12),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
          onPressed: () => launchUrl(
            Uri.parse('https://tagger.scryfall.com'),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Browse tags on Scryfall Tagger'),
        ),
      ],
    );
  }
}
