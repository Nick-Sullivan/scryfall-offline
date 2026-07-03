import 'package:flutter/material.dart';

import '../data/sync/sync_progress.dart';

/// Shared progress renderer for onboarding and update flows.
class SyncProgressView extends StatelessWidget {
  final SyncProgress progress;

  const SyncProgressView({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final (label, fraction) = switch (progress) {
      SyncChecking() => ('Checking for the latest card data…', null),
      SyncDownloading(:final file, :final receivedBytes, :final fraction) => (
          'Downloading $file (${_mb(receivedBytes)} MB)…',
          fraction,
        ),
      SyncIngesting(:final file, :final processed, :final approxTotal) => (
          file == 'cards'
              ? 'Processing cards ($processed${approxTotal > 0 ? ' of ~$approxTotal' : ''})…'
              : 'Processing rulings…',
          approxTotal > 0 ? (processed / approxTotal).clamp(0.0, 1.0) : null,
        ),
      SyncFinalizing() => ('Building search index…', null),
      SyncSwapping() => ('Finishing up…', null),
      SyncDone(:final cards, :final prints) => (
          'Done — $cards cards, $prints printings.',
          1.0,
        ),
      SyncFailed(:final message) => ('Sync failed: $message', null),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (progress is! SyncFailed && progress is! SyncDone)
          LinearProgressIndicator(value: fraction),
        const SizedBox(height: 12),
        Text(
          label,
          style: progress is SyncFailed
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
      ],
    );
  }

  String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
}
