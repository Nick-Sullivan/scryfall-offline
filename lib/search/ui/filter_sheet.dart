import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'filter_form.dart';

/// Tap-friendly filter builder, anchored to the TOP half of the screen so the
/// on-screen keyboard (bottom) never covers it. Every change applies **live**
/// — it updates the persisted [filterProvider] and re-runs the search
/// immediately, so results (visible below the panel) update in realtime.
/// Selections persist, so reopening shows exactly what's applied.
Future<void> showFilterSheet(BuildContext context, WidgetRef ref) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Filters',
    // Light scrim so the live-updating results stay visible below the panel.
    barrierColor: Colors.black.withValues(alpha: 0.06),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const Align(
      alignment: Alignment.topCenter,
      child: _FilterPanel(),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _FilterPanel extends ConsumerWidget {
  const _FilterPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);

    void push(FilterState next) {
      ref.read(filterProvider.notifier).set(next);
      ref.read(searchProvider.notifier).setQuery(next.toSyntax());
    }

    return Material(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.5,
        width: double.infinity,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Text('Filters',
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    TextButton(
                      // Back to the user's default filter (see Settings).
                      onPressed: () {
                        ref.read(filterProvider.notifier).reset();
                        ref
                            .read(searchProvider.notifier)
                            .setQuery(ref.read(filterProvider).toSyntax());
                      },
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(child: FilterForm(value: filter, onChanged: push)),
            ],
          ),
        ),
      ),
    );
  }
}
