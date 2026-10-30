import 'dart:convert';

import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/app/providers.dart';

void main() {
  group('FilterState.toSyntax', () {
    test('defaults produce an empty query', () {
      expect(const FilterState().toSyntax(), '');
    });

    test('colors honor the comparison mode', () {
      expect(
        const FilterState(colors: {'W', 'U'}, colorMode: ':').toSyntax(),
        'c:wu',
      );
      expect(
        const FilterState(colors: {'R'}, colorMode: '=').toSyntax(),
        'c=r',
      );
      expect(
        const FilterState(colors: {'G', 'W'}, colorMode: '<=').toSyntax(),
        'c<=gw',
      );
    });

    test('identity, mana value range, format', () {
      expect(
        const FilterState(
          identity: {'W', 'U', 'B'},
          mv: RangeValues(2, 5),
          format: 'commander',
        ).toSyntax(),
        'id:wub mv>=2 mv<=5 f:commander',
      );
    });

    test('open-ended mana value omits the untouched bound', () {
      expect(const FilterState(mv: RangeValues(3, 16)).toSyntax(), 'mv>=3');
      expect(const FilterState(mv: RangeValues(0, 6)).toSyntax(), 'mv<=6');
    });

    test('single vs multiple rarities', () {
      expect(const FilterState(rarities: {'mythic'}).toSyntax(), 'r:mythic');
      expect(
        const FilterState(rarities: {'rare', 'mythic'}).toSyntax(),
        anyOf('(r:rare or r:mythic)', '(r:mythic or r:rare)'),
      );
    });

    test('selected types emit one lowercased t: term each', () {
      expect(const FilterState(types: {'Creature'}).toSyntax(), 't:creature');
      expect(
        const FilterState(types: {'Legendary', 'Elf'}).toSyntax(),
        't:legendary t:elf',
      );
    });

    test('selected oracle tags emit otag: terms keyed by slug', () {
      expect(
        const FilterState(otags: {'removal': 'Removal'}).toSyntax(),
        'otag:removal',
      );
      expect(
        const FilterState(
          otags: {'removal': 'Removal', 'mana-rock': 'Mana Rock'},
        ).toSyntax(),
        'otag:removal otag:mana-rock',
      );
    });

    test('rules text words become separate ANDed terms (Scryfall form)', () {
      expect(
        const FilterState(oracleText: 'trample hexproof').toSyntax(),
        'o:trample o:hexproof',
      );
      expect(
        const FilterState(oracleText: '"draw a card"').toSyntax(),
        'o:"draw a card"',
      );
      expect(
        const FilterState(oracleText: '"enters tapped" haste').toSyntax(),
        'o:"enters tapped" o:haste',
      );
      // A half-typed quote never yields unparseable syntax.
      expect(const FilterState(oracleText: '"draw a').toSyntax(), 'o:draw o:a');
    });

    test('card name words become separate name: terms', () {
      expect(const FilterState(nameText: 'bolt').toSyntax(), 'name:bolt');
      expect(
        const FilterState(nameText: 'lightning bolt').toSyntax(),
        'name:lightning name:bolt',
      );
    });

    test('colorless compiles to c:c / id:c', () {
      expect(const FilterState(colors: {'C'}).toSyntax(), 'c:c');
      expect(const FilterState(identity: {'C'}).toSyntax(), 'id:c');
    });

    test('sort emits order+direction only when non-default', () {
      expect(
        const FilterState(sort: 'name', sortAscending: true).toSyntax(),
        '',
      );
      expect(
        const FilterState(sort: 'cmc').toSyntax(),
        'order:cmc direction:asc',
      );
      expect(
        const FilterState(sort: 'released', sortAscending: false).toSyntax(),
        'order:released direction:desc',
      );
      expect(
        const FilterState(sort: 'name', sortAscending: false).toSyntax(),
        'order:name direction:desc',
      );
      expect(
        const FilterState(sort: 'set', sortAscending: false).toSyntax(),
        'order:set direction:desc',
      );
    });

    test('set code', () {
      expect(const FilterState(setCode: 'neo').toSyntax(), 's:neo');
    });

    test('showing printings emits unique:prints', () {
      expect(const FilterState(printings: true).toSyntax(), 'unique:prints');
      expect(
        const FilterState(sort: 'set', printings: true).toSyntax(),
        'order:set direction:asc unique:prints',
      );
    });

    test('art tags emit atag:, separate from oracle tags', () {
      expect(
        const FilterState(
          otags: {'removal': 'removal'},
          atags: {'dragon': 'dragon', 'night-sky': 'night sky'},
        ).toSyntax(),
        'otag:removal atag:dragon atag:night-sky',
      );
    });

    test('power and toughness ranges; the top stop is open-ended', () {
      expect(
        const FilterState(pow: RangeValues(3, 5)).toSyntax(),
        'pow>=3 pow<=5',
      );
      expect(const FilterState(tou: RangeValues(2, 10)).toSyntax(), 'tou>=2');
      expect(const FilterState(tou: RangeValues(0, 4)).toSyntax(), 'tou<=4');
      // Full ranges add nothing, so non-creatures aren't filtered out.
      expect(const FilterState().toSyntax(), '');
    });
  });

  group('FilterState sections', () {
    // One filter per section, each setting only that section.
    final cases = {
      FilterSection.name: const FilterState(nameText: 'bolt'),
      FilterSection.types: const FilterState(types: {'Elf'}),
      FilterSection.rulesText: const FilterState(oracleText: 'draw'),
      FilterSection.oracleTags: const FilterState(otags: {'ramp': 'ramp'}),
      FilterSection.artTags: const FilterState(atags: {'cat': 'cat'}),
      FilterSection.colors: const FilterState(colors: {'R'}, colorMode: '='),
      FilterSection.identity: const FilterState(identity: {'G'}),
      FilterSection.manaValue: const FilterState(mv: RangeValues(1, 16)),
      FilterSection.power: const FilterState(pow: RangeValues(0, 4)),
      FilterSection.toughness: const FilterState(tou: RangeValues(1, 10)),
      FilterSection.format: const FilterState(format: 'modern'),
      FilterSection.rarity: const FilterState(rarities: {'rare'}),
      FilterSection.set: const FilterState(setCode: 'neo', setLabel: 'NEO'),
      FilterSection.sort: const FilterState(sort: 'cmc', sortAscending: false),
      FilterSection.show: const FilterState(printings: true),
    };

    test('defaults are inactive everywhere', () {
      for (final s in FilterSection.values) {
        expect(const FilterState().isActive(s), isFalse, reason: s.name);
      }
    });

    test('each section reports its own value', () {
      expect(cases.keys.toSet(), FilterSection.values.toSet());
      for (final MapEntry(key: section, value: state) in cases.entries) {
        for (final other in FilterSection.values) {
          expect(
            state.isActive(other),
            other == section,
            reason: '${section.name} state, checking ${other.name}',
          );
        }
      }
    });

    test('cleared resets that section and leaves the rest', () {
      for (final MapEntry(key: section, value: state) in cases.entries) {
        expect(state.cleared(section).toSyntax(), '', reason: section.name);
        // Another section's value survives clearing this one.
        final other = section == FilterSection.format
            ? FilterSection.rarity
            : FilterSection.format;
        final combined = state.copyWith(
          format: 'modern',
          rarities: const {'rare'},
        );
        expect(
          combined.cleared(section).isActive(other),
          isTrue,
          reason: section.name,
        );
      }
    });
  });

  group('FilterState json', () {
    test('round-trips every field', () {
      const original = FilterState(
        nameText: 'dragon',
        types: {'Legendary', 'Creature'},
        oracleText: 'draw a card',
        otags: {'removal': 'Removal'},
        atags: {'dragon': 'Dragon'},
        colors: {'W', 'U'},
        colorMode: '<=',
        identity: {'B'},
        mv: RangeValues(2, 7),
        pow: RangeValues(1, 4),
        tou: RangeValues(2, 10),
        format: 'commander',
        rarities: {'rare', 'mythic'},
        setCode: 'neo',
        setLabel: 'Kamigawa: Neon Dynasty (neo)',
        sort: 'edhrec',
        sortAscending: false,
        printings: true,
      );
      // Through a real encode/decode, not just the maps — otags arrives as
      // Map<String, dynamic> from jsonDecode and has to survive the cast.
      final restored = FilterState.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toSyntax(), original.toSyntax());
      expect(restored.types, original.types);
      expect(restored.otags, original.otags);
      expect(restored.atags, original.atags);
      expect(restored.pow, original.pow);
      expect(restored.tou, original.tou);
      expect(restored.setLabel, original.setLabel);
    });

    test('missing fields fall back to defaults', () {
      expect(FilterState.fromJson(const {}).toSyntax(), '');
    });

    test('a filter saved before power/toughness existed loads full ranges', () {
      final old = FilterState.fromJson(const {'mvStart': 1, 'mvEnd': 16});
      expect(old.pow, const RangeValues(0, FilterState.statMax));
      expect(old.tou, const RangeValues(0, FilterState.statMax));
      expect(old.toSyntax(), 'mv>=1');
    });

    test('a filter saved before cards/printings existed shows cards', () {
      final old = FilterState.fromJson(const {'sort': 'cmc'});
      expect(old.printings, isFalse);
      expect(old.toSyntax(), 'order:cmc direction:asc');
    });
  });
}
