// Fetches a curated set of real Scryfall card objects into
// test/fixtures/cards_fixture.jsonl (one compact JSON object per line, the
// same shape as bulk JSONL). Run: dart run tool/fetch_fixtures.dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _headers = {
  'User-Agent': 'ScryfallAppFixtures/0.1 (nicholas.sullivan@skutopia.com)',
  'Accept': 'application/json',
};

// (name, set) — set empty = Scryfall's default print.
const _cards = [
  ('Lightning Bolt', 'm10'),
  ('Lightning Bolt', 'clb'), // second print: de-dup + preferred-print tests
  ('Delver of Secrets', 'isd'), // transform
  ('Fire // Ice', 'apc'), // split
  ('Bonecrusher Giant', 'eld'), // adventure
  ("Agadeem's Awakening", 'znr'), // modal_dfc
  ('Hanweir Garrison', 'emn'), // meld part
  ('Hanweir, the Writhing Township', 'emn'), // meld result
  ('Nezumi Graverobber', 'chk'), // flip
  ('Tarmogoyf', 'mm3'), // */1+* stats
  ('Student of Warfare', 'roe'), // leveler
  ('Jace, the Mind Sculptor', 'wwk'), // planeswalker
  ('Sol Ring', 'c21'), // produces {C}
  ('Black Lotus', 'lea'), // reserved + vintage restricted
  ('Once Upon a Time', 'eld'), // banned in modern
  ('History of Benalia', 'dom'), // saga
  ('Griselbrand', 'avr'), // banned in commander
];

Future<void> main() async {
  final out = File('test/fixtures/cards_fixture.jsonl');
  out.parent.createSync(recursive: true);
  final lines = <String>[];
  final rulings = <String>[];

  for (final (name, set) in _cards) {
    final uri = Uri.https('api.scryfall.com', '/cards/named', {
      'exact': name,
      if (set.isNotEmpty) 'set': set,
    });
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode != 200) {
      stderr.writeln('FAILED $name ($set): HTTP ${resp.statusCode}');
      exitCode = 1;
      continue;
    }
    final card = jsonDecode(resp.body) as Map<String, dynamic>;
    lines.add(jsonEncode(card));
    stdout.writeln('fetched ${card['name']} [${card['set']}] '
        'layout=${card['layout']}');

    // Grab rulings for a couple of cards to fixture the rulings pipeline.
    if (name == 'Tarmogoyf' || name == 'Fire // Ice') {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final r = await http.get(
          Uri.parse('https://api.scryfall.com/cards/${card['id']}/rulings'),
          headers: _headers);
      if (r.statusCode == 200) {
        final data = (jsonDecode(r.body) as Map<String, dynamic>)['data'];
        for (final ruling in data as List) {
          rulings.add(jsonEncode(ruling));
        }
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  // A minimal token object to verify the extractor skips extras.
  lines.add(jsonEncode({
    'object': 'card',
    'id': '00000000-0000-0000-0000-000000000001',
    'oracle_id': '00000000-0000-0000-0000-000000000002',
    'name': 'Treasure',
    'layout': 'token',
    'cmc': 0.0,
    'type_line': 'Token Artifact — Treasure',
    'set': 'tznr',
    'collector_number': '1',
    'rarity': 'common',
    'released_at': '2020-09-25',
    'legalities': <String, dynamic>{},
  }));

  out.writeAsStringSync('${lines.join('\n')}\n');
  File('test/fixtures/rulings_fixture.jsonl')
      .writeAsStringSync('${rulings.join('\n')}\n');
  stdout.writeln('wrote ${lines.length} cards, ${rulings.length} rulings');
}
