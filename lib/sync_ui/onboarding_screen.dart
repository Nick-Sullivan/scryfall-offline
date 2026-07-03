import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app/providers.dart';
import '../data/sync/sync_progress.dart';
import 'sync_progress_view.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(syncControllerProvider);

    // Keep the screen awake during the one long first sync.
    final running = progress != null &&
        progress is! SyncFailed &&
        progress is! SyncDone;
    WakelockPlus.toggle(enable: running);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.style,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Offline card search',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'This app downloads the full Magic: The Gathering card '
                'database from Scryfall so every search works without an '
                'internet connection.\n\n'
                '• Download: about 80 MB (Wi-Fi recommended)\n'
                '• Storage used: about 600 MB\n'
                '• Takes around 5 minutes on most phones\n\n'
                'Card images load online as you browse and stay cached.',
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 24),
              if (progress == null || progress is SyncFailed) ...[
                if (progress case SyncFailed(:final message))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Sync failed: $message',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(syncControllerProvider.notifier).start(),
                  icon: const Icon(Icons.download),
                  label: Text(progress is SyncFailed
                      ? 'Try again'
                      : 'Download card data'),
                ),
              ] else
                SyncProgressView(progress: progress),
            ],
          ),
        ),
      ),
    );
  }
}
