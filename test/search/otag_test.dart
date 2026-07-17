import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/core/errors.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/sync/ingestor.dart';
import 'package:scryfall_app/data/tags/tag_database.dart';
import 'package:scryfall_app/data/tags/tag_ingestor.dart';
import 'package:scryfall_app/search/compiler/sql_compiler.dart';
import 'package:scryfall_app/search/parser/grammar.dart';

import '../helpers/test_db.dart';

void main() {
  configureSqliteForTests();

  late Directory tmp;
  late AppDatabase db;

  setUpAll(() async {
    // Build a real tags.db file from the fixture, then open the card DB
    // with the pack attached — the same shape production uses.
    tmp = Directory.systemTemp.createTempSync('otag_test');
    final tagsFile = File('${tmp.path}/tags.db');
    final tagDb = TagDatabase.local(file: tagsFile);
    final tagIngestor = TagIngestor(tagDb);
    await tagIngestor.ingestTags(File('test/fixtures/tags_fixture.jsonl')
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(const BulkLineDecoder()));
    await tagIngestor.finalize();
    await tagDb.close();

    db = AppDatabase.local(
        file: File('${tmp.path}/cards.db'), tagPack: tagsFile);
    final ingestor = Ingestor(db);
    await ingestor.ingestCards(File('test/fixtures/cards_fixture.jsonl')
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .transform(const BulkLineDecoder()));
    await ingestor.finalize();
  });

  tearDownAll(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<List<String>> search(String query, {bool tagsInstalled = true}) async {
    final compiled = SqlCompiler.compile(ScryfallQueryParser.parse(query),
        tagsInstalled: tagsInstalled);
    final rows = await db
        .customSelect(compiled.selectSql(limit: 100, offset: 0),
            variables: [for (final p in compiled.params) Variable(p)])
        .get();
    return rows.map((r) => r.data['name'] as String).toList();
  }

  group('otag', () {
    test('matches a tag by slug', () async {
      expect(await search('otag:mana-rock'), ['Black Lotus', 'Sol Ring']);
    });

    test('field aliases oracletag and function work', () async {
      expect(await search('oracletag:mana-rock'), ['Black Lotus', 'Sol Ring']);
      expect(await search('function:mana-rock'), ['Black Lotus', 'Sol Ring']);
    });

    test('includes descendant tags transitively', () async {
      // removal -> burn -> burn-any-target
      expect(await search('otag:removal'), [
        'Bonecrusher Giant // Stomp', // grandchild tag
        'Fire // Ice', // tagged on the root itself
        'Lightning Bolt', // child tag
      ]);
      expect(await search('otag:burn'),
          ['Bonecrusher Giant // Stomp', 'Lightning Bolt']);
      expect(
          await search('otag:burn-any-target'), ['Bonecrusher Giant // Stomp']);
    });

    test('matches tag aliases (including descendants)', () async {
      expect(await search('otag:damage-spell'),
          ['Bonecrusher Giant // Stomp', 'Lightning Bolt']);
    });

    test('normalizes quoted, spaced, cased input', () async {
      expect(await search('otag:"Mana Rock"'), ['Black Lotus', 'Sol Ring']);
    });

    test('combines with other predicates and negation', () async {
      // Stomp (Bonecrusher's adventure face) is an instant too.
      expect(await search('otag:burn t:instant'),
          ['Bonecrusher Giant // Stomp', 'Lightning Bolt']);
      expect(await search('otag:burn t:creature'),
          ['Bonecrusher Giant // Stomp']);
      expect(await search('otag:card-advantage -otag:burn'), ['Griselbrand']);
    });

    test('unknown tag yields no matches', () async {
      expect(await search('otag:does-not-exist'), isEmpty);
    });

    test('rejects comparison operators and regex values', () {
      expect(() => search('otag>=removal'), throwsA(isA<QuerySemanticError>()));
      expect(() => search('otag:/re/'), throwsA(isA<QuerySemanticError>()));
    });

    test('errors helpfully when the tag pack is not installed', () {
      expect(
          () => search('otag:removal', tagsInstalled: false),
          throwsA(isA<QuerySemanticError>().having((e) => e.message, 'message',
              contains('Card data screen'))));
    });

    test('otag is a known field for suggestions', () {
      expect(
          () => search('otga:removal'),
          throwsA(isA<QuerySemanticError>()
              .having((e) => e.message, 'message', contains('otag'))));
    });
  });
}
