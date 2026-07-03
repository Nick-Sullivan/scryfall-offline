import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/sync/sync_progress.dart';
import 'sync_progress_view.dart';

class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(metaProvider).valueOrNull ?? const {};
    final progress = ref.watch(syncControllerProvider);
    final running = progress != null &&
        progress is! SyncFailed &&
        progress is! SyncDone;

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
          FilledButton.icon(
            onPressed: running
                ? null
                : () => ref.read(syncControllerProvider.notifier).start(),
            icon: const Icon(Icons.refresh),
            label: const Text('Download latest card data'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scryfall refreshes bulk data every 12 hours; card text changes '
            'rarely, so updating weekly or after a new set releases is '
            'plenty. Search keeps working while an update downloads.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
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
