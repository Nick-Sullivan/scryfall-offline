import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/core/legalities.dart';
import 'package:scryfall_app/core/colors.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/sync/ingestor.dart';

import '../helpers/test_db.dart';

Stream<Map<String, dynamic>> _fixtureStream(String path) => File(path)
    .openRead()
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .transform(const BulkLineDecoder());

void main() {
  configureSqliteForTests();

  late AppDatabase db;
  late Ingestor ingestor;

  setUpAll(() async {
    db = AppDatabase.local();
    ingestor = Ingestor(db);
    await ingestor.ingestCards(_fixtureStream('test/fixtures/cards_fixture.jsonl'));
    await ingestor
        .ingestRulings(_fixtureStream('test/fixtures/rulings_fixture.jsonl'));
    await ingestor.finalize(bulkUpdatedAt: '2026-07-03T00:00:00Z');
  });

  tearDownAll(() => db.close());

  Future<int> count(String sql) async {
    final row = await db.customSelect(sql).getSingle();
    return row.data.values.first as int;
  }

  test('row counts: dup print collapses, token skipped', () async {
    // 18 fixture objects = 17 real cards incl. a duplicate Lightning Bolt
    // print, plus 1 token (skipped).
    expect(ingestor.stats.prints, 17);
    expect(ingestor.stats.cards, 16);
    expect(await count('SELECT COUNT(*) FROM prints'), 17);
    expect(await count('SELECT COUNT(*) FROM cards'), 16);
    expect(await count("SELECT COUNT(*) FROM cards WHERE name = 'Treasure'"), 0);
  });

  test('multi-face layouts produce one face row per face', () async {
    Future<int> facesOf(String name) => count(
        "SELECT COUNT(*) FROM faces f JOIN cards c ON c.oracle_id = f.oracle_id "
        "WHERE c.name LIKE '$name%'");
    expect(await facesOf('Delver of Secrets'), 2); // transform
    expect(await facesOf('Fire // Ice'), 2); // split
    expect(await facesOf('Bonecrusher Giant'), 2); // adventure
    expect(await facesOf("Agadeem''s Awakening"), 2); // modal_dfc
    expect(await facesOf('Nezumi Graverobber'), 2); // flip
    expect(await facesOf('Hanweir Garrison'), 1); // meld part
    expect(await facesOf('Lightning Bolt'), 1);
  });

  test('transform back face carries its own fields', () async {
    final row = await db.customSelect(
        "SELECT name, mana_pips, colors, oracle_text FROM faces "
        "WHERE name = 'Insectile Aberration'").getSingle();
    expect(row.data['mana_pips'], '');
    expect(row.data['colors'], maskU);
    expect(row.data['oracle_text'], contains('Flying'));
  });

  test('star stats fold to numbers, literals preserved', () async {
    final goyf = await db.customSelect(
        "SELECT pow_text, pow_num, tou_text, tou_num FROM faces "
        "WHERE name = 'Tarmogoyf'").getSingle();
    expect(goyf.data['pow_text'], '*');
    expect(goyf.data['pow_num'], 0);
    expect(goyf.data['tou_text'], '1+*');
    expect(goyf.data['tou_num'], 1);
  });

  test('legalities pack round-trips', () async {
    Future<int> legalitiesOf(String name) async =>
        (await db.customSelect("SELECT legalities FROM cards WHERE name = '$name'")
                .getSingle())
            .data['legalities'] as int;

    final lotus = await legalitiesOf('Black Lotus');
    expect(legalityStatus(lotus, 'vintage'), statusRestricted);
    expect(legalityStatus(lotus, 'modern'), statusNotLegal);
    expect(legalityStatus(lotus, 'commander'), statusBanned);

    final ouat = await legalitiesOf('Once Upon a Time');
    expect(legalityStatus(ouat, 'modern'), statusBanned);
    expect(legalityStatus(ouat, 'legacy'), statusLegal);
  });

  test('reserved list and produced mana', () async {
    expect(
        await count(
            "SELECT COUNT(*) FROM cards WHERE name = 'Black Lotus' AND reserved = 1"),
        1);
    final solRing = await db
        .customSelect("SELECT produced_mana FROM cards WHERE name = 'Sol Ring'")
        .getSingle();
    expect((solRing.data['produced_mana'] as int) & maskC, maskC);
  });

  test('mana pips canonicalize', () async {
    final agadeem = await db.customSelect(
        "SELECT mana_pips FROM faces WHERE name = 'Agadeem''s Awakening'")
        .getSingle();
    expect(agadeem.data['mana_pips'], 'B|B|B|X');
    final bolt = await db
        .customSelect("SELECT mana_pips FROM faces WHERE name = 'Lightning Bolt'")
        .getSingle();
    expect(bolt.data['mana_pips'], 'R');
  });

  test('preferred print and first release chosen across printings', () async {
    final bolt = await db.customSelect(
        "SELECT preferred_print_id, released_at_first FROM cards "
        "WHERE name = 'Lightning Bolt'").getSingle();
    final preferred = bolt.data['preferred_print_id'] as String?;
    expect(preferred, isNotNull);
    final prints = await db
        .customSelect("SELECT id, released_at FROM prints p JOIN cards c "
            "ON c.oracle_id = p.oracle_id WHERE c.name = 'Lightning Bolt'")
        .get();
    expect(prints, hasLength(2));
    final earliest = prints
        .map((r) => r.data['released_at'] as double)
        .reduce((a, b) => a < b ? a : b);
    expect(bolt.data['released_at_first'], earliest);
  });

  test('FTS trigram indexes answer substring queries', () async {
    // Name substring via face_name_fts.
    expect(
        await count("SELECT COUNT(*) FROM faces WHERE id IN "
            "(SELECT rowid FROM face_name_fts WHERE name LIKE '%graverobber%')"),
        1);
    // Oracle-text substring via face_text_fts (Griselbrand draws seven).
    expect(
        await count("SELECT COUNT(*) FROM faces WHERE id IN "
            "(SELECT rowid FROM face_text_fts WHERE oracle_text LIKE '%draw seven cards%')"),
        1);
  });

  test('custom SQL functions are registered', () async {
    expect(
        await count("SELECT COUNT(*) FROM faces "
            "WHERE regexp('^\\{T\\}: Add', oracle_text)"),
        greaterThanOrEqualTo(1)); // Sol Ring
    expect(
        await count("SELECT COUNT(*) FROM faces "
            "WHERE mana_geq(mana_pips, 'B|B|B') AND name LIKE 'Agadeem%'"),
        1);
    expect(
        await count(
            "SELECT COUNT(*) FROM faces WHERE mana_eq(mana_pips, 'R') "
            "AND name = 'Lightning Bolt'"),
        1);
  });

  test('rulings ingested and joinable', () async {
    expect(ingestor.stats.rulings, greaterThan(0));
    expect(
        await count("SELECT COUNT(*) FROM rulings r JOIN cards c "
            "ON c.oracle_id = r.oracle_id WHERE c.name = 'Tarmogoyf'"),
        greaterThan(0));
  });

  test('meta rows written', () async {
    final meta = await db.customSelect(
        "SELECT value FROM meta WHERE key = 'bulkUpdatedAt'").getSingle();
    expect(meta.data['value'], '2026-07-03T00:00:00Z');
  });
}
