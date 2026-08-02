import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/search/ui/filter_form.dart';

void main() {
  // Slugs and labels as the real tag pack stores them: most Scryfall cycle
  // tags have a kebab-case label identical to their slug, while curated tags
  // get a spaced one.
  const tags = <(String, String)>[
    ('cycle-snc-r-shard-removal', 'cycle-snc-r-shard-removal'),
    ('cycle-tsp-time-removal', 'cycle-tsp-time-removal'),
    ('multi-removal', 'multi removal'),
    ('removal', 'removal'),
    ('removal-aura', 'removal-aura'),
    ('mana-rock', 'mana rock'),
  ];

  group('rankOracleTags', () {
    test('exact match leads, then prefixes, then substrings', () {
      final hits = rankOracleTags(tags, 'removal', const {});
      expect(hits.map((t) => t.$1), [
        'removal',
        'removal-aura',
        'cycle-snc-r-shard-removal',
        'cycle-tsp-time-removal',
        'multi-removal',
      ]);
    });

    test('partial query still ranks prefixes above buried matches', () {
      final hits = rankOracleTags(tags, 'remov', const {});
      expect(hits.first.$1, 'removal');
      expect(hits[1].$1, 'removal-aura');
    });

    test('matches a spaced label as well as a slug', () {
      expect(rankOracleTags(tags, 'mana r', const {}).single.$1, 'mana-rock');
      expect(rankOracleTags(tags, 'mana-r', const {}).single.$1, 'mana-rock');
    });

    test('already-selected tags are excluded', () {
      final hits = rankOracleTags(tags, 'removal', const {'removal'});
      expect(hits.map((t) => t.$1), isNot(contains('removal')));
      expect(hits.first.$1, 'removal-aura');
    });

    test('caps suggestions at 20', () {
      final many = [
        for (var i = 0; i < 50; i++) ('tag-$i', 'tag $i'),
      ];
      expect(rankOracleTags(many, 'tag', const {}).length, 20);
    });

    test('no matches yields an empty list', () {
      expect(rankOracleTags(tags, 'zzz', const {}), isEmpty);
    });
  });
}
