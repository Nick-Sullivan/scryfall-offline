import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/core/errors.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/repo/card_repository.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/sync/ingestor.dart';
import 'package:scryfall_app/data/tags/tag_database.dart';
import 'package:scryfall_app/data/tags/tag_ingestor.dart';
import 'package:scryfall_app/search/compiler/sql_compiler.dart';
import 'package:scryfall_app/search/parser/grammar.dart';

import '../helpers/test_db.dart';

Stream<Map<String, dynamic>> _fixture(String name) =>
    File('test/fixtures/$name')
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(const BulkLineDecoder());

// Lightning Bolt has two printings in the card fixture; only the M10 art is
// tagged, and the preferred print is the newer CLB one.
const _boltM10 = '435589bb-27c6-4a6d-9d63-394d5092b9d8';
const _delverIsd = '11bf83bb-c95b-4b4f-9a56-ce7a1816307a';

void main() {
  configureSqliteForTests();

  late Directory tmp;
  late AppDatabase db;
  late CardRepository repo;

  setUpAll(() async {
    // A combined pack (both bulk files) attached to a real card DB — the
    // same shape production uses.
    tmp = Directory.systemTemp.createTempSync('atag_test');
    final tagsFile = File('${tmp.path}/tags.db');
    final tagDb = TagDatabase.local(file: tagsFile);
    final tagIngestor = TagIngestor(tagDb);
    await tagIngestor.ingestTags(_fixture('tags_fixture.jsonl'));
    await tagIngestor.ingestTags(_fixture('art_tags_fixture.jsonl'));
    await tagIngestor.finalize();
    await tagDb.close();

    db = AppDatabase.local(
      file: File('${tmp.path}/cards.db'),
      tagPack: tagsFile,
    );
    final ingestor = Ingestor(db);
    await ingestor.ingestCards(_fixture('cards_fixture.jsonl'));
    await ingestor.finalize();
    repo = CardRepository(db);
  });

  tearDownAll(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  CompiledQuery compile(
    String query, {
    bool artTagsInstalled = true,
    bool artIndexed = true,
  }) => SqlCompiler.compile(
    ScryfallQueryParser.parse(query),
    artTagsInstalled: artTagsInstalled,
    artIndexed: artIndexed,
  );

  Future<List<CardSummary>> rows(String query) =>
      repo.searchRows(compile(query), limit: 100, offset: 0);

  Future<List<String>> search(String query) async => [
    for (final r in await rows(query)) r.name,
  ];

  group('print_art ingest', () {
    test('one row per distinct illustration, per face for DFCs', () async {
      Future<List<String>> artOf(String printId) async => [
        for (final r
            in await db
                .customSelect(
                  'SELECT illustration_id FROM print_art WHERE print_id = ? '
                  'ORDER BY illustration_id',
                  variables: [Variable(printId)],
                )
                .get())
          r.data['illustration_id'] as String,
      ];
      expect(await artOf(_delverIsd), [
        '1c2fee9b-89ea-4ab1-a751-451c3cd65a88',
        'c2b5f731-771b-4949-90f3-0ad40d676100',
      ]);
      // Split cards repeat the shared illustration on a face; stored once.
      expect(await artOf('f98f4538-5b5b-475d-b98f-49d01dae6f04'), [
        'c890cb20-7e04-4ad0-96a6-8854cd409c14',
      ]);
      expect(await artOf(_boltM10), ['013e7eda-ef8e-44cd-9832-4033d9de1c34']);
    });
  });

  group('atag', () {
    test('matches a tag by slug, and alias field names', () async {
      expect(await search('atag:lightning'), ['Lightning Bolt']);
      expect(await search('arttag:lightning'), ['Lightning Bolt']);
      expect(await search('art:lightning'), ['Lightning Bolt']);
    });

    test('includes descendant tags and matches aliases', () async {
      expect(await search('atag:fire'), ['Fire // Ice', 'Lightning Bolt']);
      expect(await search('atag:Electricity'), ['Lightning Bolt']);
    });

    test('matches art on any face of a double-faced print', () async {
      expect(await search('atag:insect'), [
        'Delver of Secrets // Insectile Aberration',
      ]);
    });

    test('combines with other predicates and negation', () async {
      expect(await search('atag:fire t:instant -atag:lightning'), [
        'Fire // Ice',
      ]);
    });

    test('is separate from oracle tags', () async {
      expect(await search('otag:lightning'), isEmpty);
      expect(await search('atag:burn'), isEmpty);
    });

    test('errors with directions when unavailable', () {
      expect(
        () => compile('atag:fire', artTagsInstalled: false),
        throwsA(
          isA<QuerySemanticError>().having(
            (e) => e.message,
            'message',
            contains('Card data screen'),
          ),
        ),
      );
      expect(
        () => compile('atag:fire', artIndexed: false),
        throwsA(
          isA<QuerySemanticError>().having(
            (e) => e.message,
            'message',
            contains('card data'),
          ),
        ),
      );
      expect(() => compile('atag>=fire'), throwsA(isA<QuerySemanticError>()));
    });
  });

  group('displayed print', () {
    test('shows the printing whose art matched', () async {
      final bolt = (await rows('atag:lightning')).single;
      expect(bolt.printId, _boltM10);
      expect(bolt.isPreferredPrint, isFalse);
    });

    test('keeps the preferred print without an art term', () async {
      final bolt = (await rows('!"Lightning Bolt"')).single;
      expect(bolt.printId, isNot(_boltM10));
      expect(bolt.isPreferredPrint, isTrue);
      expect(compile('t:instant').displayPrint, isNull);
    });

    test('ignores art terms under NOT or OR', () async {
      expect(compile('-atag:lightning').displayPrint, isNull);
      expect(compile('atag:lightning or t:creature').displayPrint, isNull);
      final bolt = (await rows(
        'atag:lightning or t:creature',
      )).singleWhere((r) => r.name == 'Lightning Bolt');
      expect(bolt.isPreferredPrint, isTrue);
    });

    test('a qualifying preferred print is kept', () async {
      // Fire // Ice has a single printing, which is both.
      final fire = (await rows(
        'atag:fire',
      )).firstWhere((r) => r.name == 'Fire // Ice');
      expect(fire.isPreferredPrint, isTrue);
    });
  });

  group('CardRepository art tags', () {
    test('artTagsForPrint lists direct tags on every face', () async {
      expect(await repo.artTagsForPrint(_boltM10), [
        ('lightning', 'lightning'),
      ]);
      expect(await repo.artTagsForPrint(_delverIsd), [('insect', 'insect')]);
      expect(await repo.artTagsForPrint('nope'), isEmpty);
    });

    test('allArtTags is sorted by label and excludes oracle tags', () async {
      final tags = await repo.allArtTags();
      expect(tags.map((t) => t.$1), [
        'fire',
        'insect',
        'lightning',
        'squirrel-art',
      ]);
    });
  });
}
