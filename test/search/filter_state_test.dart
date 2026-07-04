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
          'c:wu');
      expect(
          const FilterState(colors: {'R'}, colorMode: '=').toSyntax(), 'c=r');
      expect(
          const FilterState(colors: {'G', 'W'}, colorMode: '<=').toSyntax(),
          'c<=gw');
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
      expect(
        const FilterState(oracleText: '"draw a').toSyntax(),
        'o:draw o:a',
      );
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
      expect(const FilterState(sort: 'name', sortAscending: true).toSyntax(), '');
      expect(const FilterState(sort: 'cmc').toSyntax(),
          'order:cmc direction:asc');
      expect(const FilterState(sort: 'released', sortAscending: false).toSyntax(),
          'order:released direction:desc');
      expect(const FilterState(sort: 'name', sortAscending: false).toSyntax(),
          'order:name direction:desc');
    });

    test('set code', () {
      expect(const FilterState(setCode: 'neo').toSyntax(), 's:neo');
    });
  });

  group('FilterState json', () {
    test('round-trips every field', () {
      const original = FilterState(
        nameText: 'dragon',
        types: {'Legendary', 'Creature'},
        oracleText: 'draw a card',
        colors: {'W', 'U'},
        colorMode: '<=',
        identity: {'B'},
        mv: RangeValues(2, 7),
        format: 'commander',
        rarities: {'rare', 'mythic'},
        setCode: 'neo',
        setLabel: 'Kamigawa: Neon Dynasty (neo)',
        sort: 'edhrec',
        sortAscending: false,
      );
      final restored = FilterState.fromJson(original.toJson());
      expect(restored.toSyntax(), original.toSyntax());
      expect(restored.types, original.types);
      expect(restored.setLabel, original.setLabel);
    });

    test('missing fields fall back to defaults', () {
      expect(FilterState.fromJson(const {}).toSyntax(), '');
    });
  });
}
