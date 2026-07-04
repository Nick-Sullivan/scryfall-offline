import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/repo/card_repository.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/sync/ingestor.dart';

import '../helpers/test_db.dart';

void main() {
  configureSqliteForTests();

  group('CardRepository.detail', () {
    late AppDatabase db;
    late CardRepository repo;

    setUpAll(() async {
      db = AppDatabase.local();
      final ingestor = Ingestor(db);
      await ingestor.ingestCards(File('test/fixtures/cards_fixture.jsonl')
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .transform(const BulkLineDecoder()));
      await ingestor.finalize();
      repo = CardRepository(db);
    });

    tearDownAll(() => db.close());

    test('loads the preferred print with its printings and raw json',
        () async {
      final card = await db
          .customSelect(
              'SELECT oracle_id, name, preferred_print_id FROM cards '
              'WHERE preferred_print_id IS NOT NULL LIMIT 1')
          .getSingle();
      final detail = await repo.detail(card.data['oracle_id'] as String);
      expect(detail, isNotNull);
      expect(detail!.name, card.data['name']);
      expect(detail.printings, isNotEmpty);
      expect(detail.rawJson['id'], card.data['preferred_print_id']);
    });

    test('requesting a specific print returns that print\'s raw json',
        () async {
      final print = await db
          .customSelect('SELECT id, oracle_id FROM prints LIMIT 1')
          .getSingle();
      final detail = await repo.detail(print.data['oracle_id'] as String,
          printId: print.data['id'] as String);
      expect(detail!.rawJson['id'], print.data['id']);
    });

    test('unknown print id falls back to the newest printing', () async {
      final card = await db
          .customSelect('SELECT oracle_id FROM cards LIMIT 1')
          .getSingle();
      final detail = await repo.detail(card.data['oracle_id'] as String,
          printId: 'not-a-real-print-id');
      expect(detail!.rawJson['id'], detail.printings.first.id);
    });

    test('unknown oracle id returns null', () async {
      expect(await repo.detail('not-a-real-oracle-id'), isNull);
    });
  });

  group('CardRepository.summariesByIds', () {
    test('preserves input order and drops unknown ids', () async {
      final db = AppDatabase.local();
      final ingestor = Ingestor(db);
      await ingestor.ingestCards(File('test/fixtures/cards_fixture.jsonl')
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .transform(const BulkLineDecoder()));
      await ingestor.finalize();
      addTearDown(db.close);
      final repo = CardRepository(db);

      final rows = await db
          .customSelect('SELECT oracle_id FROM cards ORDER BY name LIMIT 3')
          .get();
      final ids = [for (final r in rows) r.data['oracle_id'] as String];

      final reversed = ids.reversed.toList();
      final result =
          await repo.summariesByIds([...reversed, 'not-a-real-id']);
      expect([for (final s in result) s.oracleId], reversed);
    });
  });
}
