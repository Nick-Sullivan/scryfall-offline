import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/tags/tag_database.dart';
import 'package:scryfall_app/data/tags/tag_ingestor.dart';

import '../helpers/test_db.dart';

Stream<Map<String, dynamic>> fixtureStream() =>
    File('test/fixtures/tags_fixture.jsonl')
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(const BulkLineDecoder());

void main() {
  configureSqliteForTests();

  group('TagIngestor', () {
    late TagDatabase db;
    late TagIngestor ingestor;

    setUpAll(() async {
      db = TagDatabase.local();
      ingestor = TagIngestor(db);
      await ingestor.ingestTags(fixtureStream());
      await ingestor.finalize(bulkUpdatedAt: '2026-07-17T21:00:36.823+00:00');
    });

    tearDownAll(() => db.close());

    test('ingests oracle tags, skipping non-oracle lines', () async {
      final tags = await db.select(db.tags).get();
      // 5 oracle tags; the 'illustration' line is skipped.
      expect(tags.length, 5);
      expect(tags.map((t) => t.slug), isNot(contains('squirrel-art')));
      expect(ingestor.stats.tags, 5);
    });

    test('normalizes slugs and keeps nullable description', () async {
      final tags = await db.select(db.tags).get();
      final manaRock = tags.singleWhere((t) => t.slug == 'mana-rock');
      expect(manaRock.label, 'mana rock');
      expect(manaRock.description, 'Artifacts that produce mana.');
      final burn = tags.singleWhere((t) => t.slug == 'burn');
      expect(burn.description, isNull);
    });

    test('builds edges from parent_ids', () async {
      final edges = await db.select(db.tagEdges).get();
      expect(edges.length, 2);
      expect(
          edges.any((e) =>
              e.parentId.endsWith('01') && e.childId.endsWith('02')),
          isTrue);
      expect(
          edges.any((e) =>
              e.parentId.endsWith('02') && e.childId.endsWith('03')),
          isTrue);
    });

    test('stores aliases and taggings', () async {
      final aliases = await db.select(db.tagAliases).get();
      expect(aliases.single.alias, 'damage-spell');

      final cards = await db.select(db.tagCards).get();
      expect(cards.length, 7);
      expect(ingestor.stats.taggings, 7);
    });

    test('writes meta entries', () async {
      final meta = {
        for (final r in await db.select(db.tagPackMeta).get()) r.key: r.value
      };
      expect(meta[TagPackMetaKeys.tagCount], '5');
      expect(meta[TagPackMetaKeys.taggingCount], '7');
      expect(meta[TagPackMetaKeys.bulkUpdatedAt],
          '2026-07-17T21:00:36.823+00:00');
      expect(DateTime.tryParse(meta[TagPackMetaKeys.fetchedAt] ?? ''),
          isNotNull);
    });
  });

  group('normalizeTag', () {
    test('folds user input to kebab-case', () {
      expect(normalizeTag('Grave Pact'), 'grave-pact');
      expect(normalizeTag('  burn  any   target '), 'burn-any-target');
      expect(normalizeTag('removal'), 'removal');
    });
  });
}
