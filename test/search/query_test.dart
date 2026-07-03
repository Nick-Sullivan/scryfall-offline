import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/core/errors.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/sync/ingestor.dart';
import 'package:scryfall_app/search/compiler/sql_compiler.dart';
import 'package:scryfall_app/search/parser/ast.dart';
import 'package:scryfall_app/search/parser/grammar.dart';

import '../helpers/test_db.dart';

void main() {
  configureSqliteForTests();

  group('parser', () {
    test('implicit AND binds tighter than or', () {
      final node = ScryfallQueryParser.parse('t:goblin or t:elf c:g');
      expect(node, isA<OrNode>());
      final or = node as OrNode;
      expect(or.children.first, isA<PredicateNode>());
      expect(or.children.last, isA<AndNode>());
    });

    test('negation and parens', () {
      final node = ScryfallQueryParser.parse('-(t:creature or t:land) bolt');
      final and = node as AndNode;
      expect(and.children.first, isA<NotNode>());
      expect((and.children.last as NameTermNode).text, 'bolt');
    });

    test('quoted phrases, exact names, regex values', () {
      var node = ScryfallQueryParser.parse('o:"enters tapped"');
      expect(((node as PredicateNode).value as StringValue).text,
          'enters tapped');
      node = ScryfallQueryParser.parse('!"Fire // Ice"');
      expect((node as NameTermNode).exact, isTrue);
      node = ScryfallQueryParser.parse(r'o:/^\{T\}: Add/');
      expect((node as PredicateNode).value, isA<RegexValue>());
    });

    test('syntax errors carry a position', () {
      expect(
          () => ScryfallQueryParser.parse('(t:creature'),
          throwsA(isA<QuerySyntaxError>()));
      expect(() => ScryfallQueryParser.parse('   '),
          throwsA(isA<QuerySyntaxError>()));
    });
  });

  group('compiler + execution', () {
    late AppDatabase db;

    setUpAll(() async {
      db = AppDatabase.local();
      final ingestor = Ingestor(db);
      await ingestor.ingestCards(File('test/fixtures/cards_fixture.jsonl')
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .transform(const BulkLineDecoder()));
      await ingestor.finalize();
    });

    tearDownAll(() => db.close());

    Future<List<String>> search(String query) async {
      final compiled =
          SqlCompiler.compile(ScryfallQueryParser.parse(query));
      final rows = await db
          .customSelect(compiled.selectSql(limit: 100, offset: 0),
              variables: [for (final p in compiled.params) Variable(p)])
          .get();
      return rows.map((r) => r.data['name'] as String).toList();
    }

    test('exact name', () async {
      expect(await search('!"Lightning Bolt"'), ['Lightning Bolt']);
    });

    test('name substring matches faces', () async {
      expect(await search('graverobber'),
          ['Nezumi Graverobber // Nighteyes the Desecrator']);
      expect(await search('bolt'), ['Lightning Bolt']);
    });

    test('type + color conjunction', () async {
      final names = await search('t:instant c:r');
      expect(names, containsAll(['Lightning Bolt', 'Fire // Ice']));
      expect(names, isNot(contains('Griselbrand')));
    });

    test('oracle text substring', () async {
      expect(await search('o:"draw seven cards"'), ['Griselbrand']);
    });

    test('numeric mana value with type', () async {
      final names = await search('mv<=1 t:artifact');
      expect(names.toSet(), {'Black Lotus', 'Sol Ring'});
    });

    test('field-vs-field pow>tou checks every face', () async {
      final names = await search('pow>tou t:creature');
      expect(
          names.toSet(),
          {
            'Bonecrusher Giant // Stomp',
            'Hanweir, the Writhing Township',
            'Nezumi Graverobber // Nighteyes the Desecrator',
            'Delver of Secrets // Insectile Aberration', // 3/2 back face
          });
    });

    test('banned/restricted/format legality', () async {
      expect(await search('banned:modern'), ['Once Upon a Time']);
      expect((await search('restricted:vintage')).toSet(),
          {'Black Lotus', 'Sol Ring'});
      final commander = await search('f:commander t:creature');
      expect(commander, isNot(contains('Griselbrand'))); // banned in EDH
    });

    test('is: predicates', () async {
      expect(await search('is:reserved'), ['Black Lotus']);
      expect(await search('is:split'), ['Fire // Ice']);
      expect(await search('is:transform'),
          ['Delver of Secrets // Insectile Aberration']);
    });

    test('negation excludes adventure creature from instants', () async {
      final names = await search('-t:creature t:instant');
      expect(names, isNot(contains('Bonecrusher Giant // Stomp')));
      expect(names, containsAll(['Lightning Bolt', 'Fire // Ice']));
    });

    test('mana cost multiset comparisons', () async {
      expect((await search('m>=bbb')).toSet(), {
        "Agadeem's Awakening // Agadeem, the Undercrypt",
        'Griselbrand', // {4}{B}{B}{B}{B} contains {B}{B}{B}
      });
      expect(await search('m={R}'), ['Lightning Bolt']);
    });

    test('color set algebra', () async {
      expect(await search('c>=ur'), ['Fire // Ice']);
      final colorlessIdentity = await search('id:c');
      expect(colorlessIdentity.toSet(), {'Black Lotus', 'Sol Ring'});
    });

    test('or with parens', () async {
      final names = await search('(t:planeswalker or t:saga)');
      expect(names.toSet(),
          {'Jace, the Mind Sculptor', 'History of Benalia'});
    });

    test('keywords', () async {
      final names = await search('kw:flying');
      expect(
          names,
          containsAll(
              ['Delver of Secrets // Insectile Aberration', 'Griselbrand']));
    });

    test('print-level fields: set and year', () async {
      expect(await search('s:m10'), ['Lightning Bolt']);
      expect(await search('year<=1993'), ['Black Lotus']);
    });

    test('regex on name', () async {
      expect(await search('name:/^Tarmo/'), ['Tarmogoyf']);
    });

    test('order directives shape ORDER BY', () async {
      final names = await search('t:artifact order:cmc direction:asc');
      expect(names.first, 'Black Lotus'); // cmc 0
    });

    test('semantic errors: unknown field with suggestion, bad values', () {
      expect(
          () => SqlCompiler.compile(ScryfallQueryParser.parse('colr:red')),
          throwsA(isA<QuerySemanticError>().having(
              (e) => e.message, 'message', contains("did you mean 'color'"))));
      expect(() => SqlCompiler.compile(ScryfallQueryParser.parse('mv>=x')),
          throwsA(isA<QuerySemanticError>()));
      expect(() => SqlCompiler.compile(ScryfallQueryParser.parse('is:cube')),
          throwsA(isA<QuerySemanticError>()));
    });
  });
}
