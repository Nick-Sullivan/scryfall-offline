import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Tap-friendly filter builder. Emits real Scryfall syntax appended to the
/// search field — the query string stays the single source of truth.
Future<String?> showFilterSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  final _type = TextEditingController();
  final _text = TextEditingController();
  final _colors = <String>{};
  String _colorMode = ':';
  final _identity = <String>{};
  RangeValues _mv = const RangeValues(0, 16);
  String? _format;
  final _rarities = <String>{};
  String? _setCode;

  @override
  void dispose() {
    _type.dispose();
    _text.dispose();
    super.dispose();
  }

  String _buildSyntax() {
    final parts = <String>[];
    String quoteIfNeeded(String v) => v.contains(' ') ? '"$v"' : v;

    if (_type.text.trim().isNotEmpty) {
      parts.add('t:${quoteIfNeeded(_type.text.trim())}');
    }
    if (_text.text.trim().isNotEmpty) {
      parts.add('o:${quoteIfNeeded(_text.text.trim())}');
    }
    if (_colors.isNotEmpty) {
      parts.add('c$_colorMode${_colors.join().toLowerCase()}');
    }
    if (_identity.isNotEmpty) {
      parts.add('id:${_identity.join().toLowerCase()}');
    }
    if (_mv.start > 0) parts.add('mv>=${_mv.start.round()}');
    if (_mv.end < 16) parts.add('mv<=${_mv.end.round()}');
    if (_format != null) parts.add('f:$_format');
    if (_rarities.isNotEmpty) {
      parts.add(_rarities.length == 1
          ? 'r:${_rarities.first}'
          : '(${_rarities.map((r) => 'r:$r').join(' or ')})');
    }
    if (_setCode != null) parts.add('s:$_setCode');
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final sets = ref.watch(allSetsProvider).valueOrNull ?? const [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Row(
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(context, _buildSyntax()),
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _type,
            decoration: const InputDecoration(
              labelText: 'Type line contains',
              hintText: 'creature, legendary, elf …',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            decoration: const InputDecoration(
              labelText: 'Rules text contains',
              hintText: 'draw a card, enters tapped …',
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Colors'),
          Wrap(
            spacing: 8,
            children: [
              for (final c in 'WUBRG'.split(''))
                FilterChip(
                  label: Text(c),
                  selected: _colors.contains(c),
                  onSelected: (sel) => setState(
                      () => sel ? _colors.add(c) : _colors.remove(c)),
                ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _colorMode,
                items: const [
                  DropdownMenuItem(value: ':', child: Text('including')),
                  DropdownMenuItem(value: '=', child: Text('exactly')),
                  DropdownMenuItem(value: '<=', child: Text('at most')),
                ],
                onChanged: (v) => setState(() => _colorMode = v ?? ':'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Commander identity (at most)'),
          Wrap(
            spacing: 8,
            children: [
              for (final c in 'WUBRG'.split(''))
                FilterChip(
                  label: Text(c),
                  selected: _identity.contains(c),
                  onSelected: (sel) => setState(
                      () => sel ? _identity.add(c) : _identity.remove(c)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel(
              'Mana value  ${_mv.start.round()} – ${_mv.end.round() == 16 ? '∞' : _mv.end.round()}'),
          RangeSlider(
            values: _mv,
            min: 0,
            max: 16,
            divisions: 16,
            onChanged: (v) => setState(() => _mv = v),
          ),
          const SizedBox(height: 8),
          _sectionLabel('Format'),
          Wrap(
            spacing: 8,
            children: [
              for (final f in [
                'standard', 'pioneer', 'modern', 'legacy', 'vintage',
                'pauper', 'commander'
              ])
                ChoiceChip(
                  label: Text(f),
                  selected: _format == f,
                  onSelected: (sel) =>
                      setState(() => _format = sel ? f : null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Rarity'),
          Wrap(
            spacing: 8,
            children: [
              for (final r in formatRarities)
                FilterChip(
                  label: Text(r),
                  selected: _rarities.contains(r),
                  onSelected: (sel) => setState(
                      () => sel ? _rarities.add(r) : _rarities.remove(r)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('Set'),
          Autocomplete<(String, String)>(
            displayStringForOption: (s) => '${s.$2} (${s.$1})',
            optionsBuilder: (t) {
              final q = t.text.toLowerCase();
              if (q.isEmpty) return const Iterable.empty();
              return sets.where((s) =>
                  s.$1.contains(q) || s.$2.toLowerCase().contains(q));
            },
            onSelected: (s) => setState(() => _setCode = s.$1),
            fieldViewBuilder: (context, controller, focus, onSubmit) =>
                TextField(
              controller: controller,
              focusNode: focus,
              decoration: InputDecoration(
                labelText: 'Set name or code',
                suffixIcon: _setCode == null
                    ? null
                    : Chip(
                        label: Text(_setCode!),
                        onDeleted: () {
                          controller.clear();
                          setState(() => _setCode = null);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

const formatRarities = ['common', 'uncommon', 'rare', 'mythic'];
