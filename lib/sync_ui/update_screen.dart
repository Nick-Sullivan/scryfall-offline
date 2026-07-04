import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          _row('Last update check', _friendlyDate(meta['lastCheckAt'])),
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
                Icon(Icons.check_circle,
                    size: 18, color: Colors.green.shade700),
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
          const SizedBox(height: 8),
          const Text(
            'Scryfall refreshes bulk data every 12 hours; card text changes '
            'rarely, so updating weekly or after a new set releases is '
            'plenty. Search keeps working while an update downloads.',
            style: TextStyle(fontSize: 12),
          ),
          const Divider(height: 40),
          const _ImagePackSection(),
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

class _ImagePackSection extends ConsumerWidget {
  const _ImagePackSection();

  // Measured average for Scryfall 'normal' JPGs.
  static const _avgImageKb = 100;

  String _gb(int images) =>
      '${(images * _avgImageKb / 1024 / 1024).toStringAsFixed(1)} GB';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(imagePackProvider);
    final running = progress?.running ?? false;
    final (downloaded, total) =
        ref.watch(imagePackStatusProvider).valueOrNull ?? (0, 0);

    // Multi-hour download — keep the screen awake while it runs.
    WakelockPlus.toggle(enable: running);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offline card images',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
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
            total == 0
                ? 'No card data yet.'
                : '$downloaded of $total images downloaded '
                      '(${_gb(downloaded)} of ~${_gb(total)}).',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: total == 0 || downloaded >= total
                    ? null
                    : () => ref.read(imagePackProvider.notifier).start(),
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
          'Stores one image per card so search results and card pages work '
          'fully offline. ~3.3 GB, can take a few '
          'hours; you can stop and resume any time — already-downloaded '
          'images are kept.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
