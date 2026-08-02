import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mana_icons_flutter/mana_icons_flutter.dart';

import '../../app/providers.dart';

const _sortLabels = {
  'name': 'Name',
  'cmc': 'Mana value',
  'released': 'Release date',
  'set': 'Set',
  'edhrec': 'EDHREC rank',
  'rarity': 'Rarity',
  'power': 'Power',
};

const _rarityOptions = ['common', 'uncommon', 'rare', 'mythic'];

/// Scryfall's mana symbol fill colors and the official Mana font glyphs,
/// keyed by WUBRG letter plus C for colorless.
const _manaOptions = ['W', 'U', 'B', 'R', 'G', 'C'];

const _manaFills = {
  'W': Color(0xFFF0F2C0),
  'U': Color(0xFFB5CDE3),
  'B': Color(0xFFACA29A),
  'R': Color(0xFFEB9F82),
  'G': Color(0xFFC4D3CA),
  'C': Color(0xFFCBC5C1),
};

const _manaGlyphs = {
  'W': ManaIcons.ms_w,
  'U': ManaIcons.ms_u,
  'B': ManaIcons.ms_b,
  'R': ManaIcons.ms_r,
  'G': ManaIcons.ms_g,
  'C': ManaIcons.ms_c,
};

const _manaNames = {
  'W': 'White',
  'U': 'Blue',
  'B': 'Black',
  'R': 'Red',
  'G': 'Green',
  'C': 'Colorless',
};

/// The filter editor shared by the filter sheet (edits the live search) and
/// the settings screen (edits the persisted default). Scrolls itself; emits a
/// new [FilterState] on every committed change while transient state (slider
/// drags, half-typed text) stays internal.
class FilterForm extends ConsumerStatefulWidget {
  final FilterState value;
  final ValueChanged<FilterState> onChanged;

  /// Extra widgets shown above the first field, scrolling with the form.
  final List<Widget> header;

  const FilterForm({
    super.key,
    required this.value,
    required this.onChanged,
    this.header = const [],
  });

  @override
  ConsumerState<FilterForm> createState() => _FilterFormState();
}

class _FilterFormState extends ConsumerState<FilterForm> {
  late FilterState _draft;
  late final TextEditingController _name;
  late final TextEditingController _text;
  Timer? _textDebounce;

  @override
  void initState() {
    super.initState();
    _draft = widget.value;
    _name = TextEditingController(text: _draft.nameText);
    _text = TextEditingController(text: _draft.oracleText);
  }

  @override
  void didUpdateWidget(FilterForm old) {
    super.didUpdateWidget(old);
    // Our own commits echo back as the identical instance; anything else is
    // an external change (Reset, settings edit) — resync the draft.
    if (!identical(widget.value, _draft)) {
      _draft = widget.value;
      if (_name.text != _draft.nameText) _name.text = _draft.nameText;
      if (_text.text != _draft.oracleText) _text.text = _draft.oracleText;
    }
  }

  @override
  void dispose() {
    _textDebounce?.cancel();
    _name.dispose();
    _text.dispose();
    super.dispose();
  }

  void _apply(FilterState next) {
    setState(() => _draft = next);
    widget.onChanged(next);
  }

  void _onTextChanged() {
    _textDebounce?.cancel();
    _textDebounce = Timer(const Duration(milliseconds: 150), () {
      _apply(
          _draft.copyWith(nameText: _name.text, oracleText: _text.text));
    });
  }

  @override
  Widget build(BuildContext context) {
    final sets = ref.watch(allSetsProvider).valueOrNull ?? const [];
    final types = ref.watch(allTypesProvider).valueOrNull ?? const <String>[];
    // Empty means the optional tag pack isn't installed, which hides the
    // section entirely.
    final tags = ref.watch(allTagsProvider).valueOrNull ??
        const <(String, String)>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        ...widget.header,
        TextField(
          controller: _name,
          onChanged: (_) => _onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Card name contains',
            hintText: 'bolt, dragon …',
          ),
        ),
        const SizedBox(height: 8),
        _label('Types'),
        _ChipPicker<String>(
          suggest: (q) => types
              .where((ty) =>
                  ty.toLowerCase().contains(q) && !_draft.types.contains(ty))
              .take(20),
          display: (ty) => ty,
          label: 'Add a type',
          hint: 'creature, legendary, elf …',
          onAdd: (t) => _apply(_draft.copyWith(types: {..._draft.types, t})),
        ),
        if (_draft.types.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final t in _draft.types)
                  InputChip(
                    label: Text(t),
                    onDeleted: () => _apply(
                        _draft.copyWith(types: {..._draft.types}..remove(t))),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _text,
          onChanged: (_) => _onTextChanged(),
          decoration: const InputDecoration(
            labelText: 'Rules text contains',
            hintText: 'trample hexproof  ·  "enters tapped"',
            helperText: 'Words match separately; use "quotes" for a phrase',
          ),
        ),
        // Selected tags keep the section alive even without the pack, so a
        // saved filter's chips stay removable after deleting the tag data —
        // otherwise they'd keep emitting otag: terms the compiler rejects.
        if (tags.isNotEmpty || _draft.otags.isNotEmpty) ...[
          const SizedBox(height: 16),
          _label('Oracle tags'),
          _ChipPicker<(String, String)>(
            suggest: (q) => rankOracleTags(tags, q, _draft.otags.keys.toSet()),
            display: (t) => t.$2,
            label: 'Add a tag',
            hint: 'removal, ramp, card draw …',
            onAdd: (t) =>
                _apply(_draft.copyWith(otags: {..._draft.otags, t.$1: t.$2})),
          ),
          if (_draft.otags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in _draft.otags.entries)
                    InputChip(
                      label: Text(e.value),
                      onDeleted: () => _apply(_draft.copyWith(
                          otags: {..._draft.otags}..remove(e.key))),
                    ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 16),
        _label('Colors'),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final c in _manaOptions)
              _ManaDot(
                letter: c,
                selected: _draft.colors.contains(c),
                onTap: () => _apply(
                    _draft.copyWith(colors: _toggleColor(_draft.colors, c))),
              ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _draft.colorMode,
              items: const [
                DropdownMenuItem(value: ':', child: Text('including')),
                DropdownMenuItem(value: '=', child: Text('exactly')),
                DropdownMenuItem(value: '<=', child: Text('at most')),
              ],
              onChanged: (v) => _apply(_draft.copyWith(colorMode: v ?? ':')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Commander identity (at most)'),
        Wrap(
          spacing: 8,
          children: [
            for (final c in _manaOptions)
              _ManaDot(
                letter: c,
                selected: _draft.identity.contains(c),
                onTap: () => _apply(_draft.copyWith(
                    identity: _toggleColor(_draft.identity, c))),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Mana value  ${_draft.mv.start.round()} – '
            '${_draft.mv.end.round() == 16 ? '∞' : _draft.mv.end.round()}'),
        RangeSlider(
          values: _draft.mv,
          min: 0,
          max: 16,
          divisions: 16,
          // No value-indicator boxes — the label line above updates live.
          onChanged: (v) => setState(() => _draft = _draft.copyWith(mv: v)),
          onChangeEnd: (v) => _apply(_draft.copyWith(mv: v)),
        ),
        const SizedBox(height: 8),
        _label('Format'),
        Wrap(
          spacing: 8,
          children: [
            for (final f in const [
              'standard', 'pioneer', 'modern', 'legacy', 'vintage',
              'pauper', 'commander'
            ])
              ChoiceChip(
                label: Text(f),
                selected: _draft.format == f,
                onSelected: (sel) => _apply(sel
                    ? _draft.copyWith(format: f)
                    : _draft.copyWith(clearFormat: true)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Rarity'),
        Wrap(
          spacing: 8,
          children: [
            for (final r in _rarityOptions)
              FilterChip(
                label: Text(r),
                selected: _draft.rarities.contains(r),
                onSelected: (sel) => _apply(_draft.copyWith(
                    rarities: _toggle(_draft.rarities, r, sel))),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _label('Set'),
        Autocomplete<(String, String)>(
          initialValue: TextEditingValue(text: _draft.setLabel ?? ''),
          displayStringForOption: (s) => '${s.$2} (${s.$1})',
          optionsBuilder: (t) {
            final q = t.text.toLowerCase();
            if (q.isEmpty) return const Iterable.empty();
            return sets.where(
                (s) => s.$1.contains(q) || s.$2.toLowerCase().contains(q));
          },
          onSelected: (s) => _apply(
              _draft.copyWith(setCode: s.$1, setLabel: '${s.$2} (${s.$1})')),
          fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
            controller: controller,
            focusNode: focus,
            decoration: InputDecoration(
              labelText: 'Set name or code',
              suffixIcon: _draft.setCode == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        _apply(_draft.copyWith(clearSet: true));
                      },
                    ),
            ),
          ),
        ),
        const Divider(height: 32),
        _label('Sort by'),
        Wrap(
          spacing: 8,
          children: [
            for (final e in _sortLabels.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: _draft.sort == e.key,
                onSelected: (_) => _apply(_draft.copyWith(sort: e.key)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Ascending')),
            ButtonSegment(value: false, label: Text('Descending')),
          ],
          selected: {_draft.sortAscending},
          onSelectionChanged: (s) =>
              _apply(_draft.copyWith(sortAscending: s.first)),
        ),
      ],
    );
  }

  Set<String> _toggle(Set<String> set, String value, bool add) {
    final next = {...set};
    add ? next.add(value) : next.remove(value);
    return next;
  }

  /// Colorless can't combine with colors (`c:wc` is invalid syntax), so
  /// picking C replaces the selection and picking a color drops C.
  Set<String> _toggleColor(Set<String> set, String value) {
    if (set.contains(value)) return {...set}..remove(value);
    if (value == 'C') return {'C'};
    return {...set}
      ..remove('C')
      ..add(value);
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

/// Oracle tags matching [query] on label or slug, best match first. Straight
/// alphabetical order buries the tag you asked for — "removal" sorts behind
/// cycle-snc-r-shard-removal and friends — so exact matches lead, then
/// prefixes, then anything else containing the query.
@visibleForTesting
List<(String, String)> rankOracleTags(
  List<(String, String)> tags,
  String query,
  Set<String> exclude,
) {
  int rank((String, String) t) {
    final label = t.$2.toLowerCase();
    if (t.$1 == query || label == query) return 0;
    if (t.$1.startsWith(query) || label.startsWith(query)) return 1;
    return 2;
  }

  final hits = [
    for (final t in tags)
      if (!exclude.contains(t.$1) &&
          (t.$2.toLowerCase().contains(query) || t.$1.contains(query)))
        t
  ];
  // sort() isn't stable, so tie-break on label to keep the order fixed.
  hits.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    return byRank != 0 ? byRank : a.$2.compareTo(b.$2);
  });
  return hits.take(20).toList();
}

/// Type-to-search field that feeds a row of chips: picking a suggestion adds
/// it and clears the field for the next one. [suggest] owns the matching and
/// drops anything already selected; an empty query never opens the dropdown.
class _ChipPicker<T extends Object> extends StatefulWidget {
  final Iterable<T> Function(String query) suggest;
  final String Function(T) display;
  final ValueChanged<T> onAdd;
  final String label;
  final String hint;

  const _ChipPicker({
    super.key,
    required this.suggest,
    required this.display,
    required this.onAdd,
    required this.label,
    required this.hint,
  });

  @override
  State<_ChipPicker<T>> createState() => _ChipPickerState<T>();
}

class _ChipPickerState<T extends Object> extends State<_ChipPicker<T>> {
  TextEditingController? _field;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<T>(
      displayStringForOption: widget.display,
      optionsBuilder: (t) {
        final q = t.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable.empty();
        return widget.suggest(q);
      },
      onSelected: (t) {
        widget.onAdd(t);
        // The field is only a search box — the chips are the state, so wipe
        // it once Autocomplete has written the selection back.
        Future.microtask(() => _field?.clear());
      },
      fieldViewBuilder: (context, controller, focus, onSubmit) {
        _field = controller;
        return TextField(
          controller: controller,
          focusNode: focus,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
          ),
          onTapOutside: (_) => focus.unfocus(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    dense: true,
                    title: Text(widget.display(o)),
                    onTap: () => onSelected(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An official mana symbol (Mana font) on its Scryfall-colored disc. Selected
/// symbols get a primary ring.
class _ManaDot extends StatelessWidget {
  final String letter;
  final bool selected;
  final VoidCallback onTap;

  const _ManaDot({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: _manaNames[letter]!,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _manaFills[letter],
            border: Border.all(
              color: selected ? scheme.primary : Colors.black26,
              width: selected ? 3 : 1,
            ),
          ),
          // 0xFF130C0E is the symbol ink color the Mana font is designed for.
          child: Icon(_manaGlyphs[letter],
              size: 20, color: const Color(0xFF130C0E)),
        ),
      ),
    );
  }
}
