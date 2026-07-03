import 'dart:convert';

import 'package:drift/drift.dart';

import '../../search/compiler/sql_compiler.dart';
import '../db/database.dart';

/// One search-result tile (oracle grain + its preferred print's images).
class CardSummary {
  final String oracleId;
  final String name;
  final String? manaCost;
  final String typeLine;
  final String? imageSmall;
  final String? imageNormal;

  const CardSummary({
    required this.oracleId,
    required this.name,
    required this.manaCost,
    required this.typeLine,
    required this.imageSmall,
    required this.imageNormal,
  });
}

class SearchPage {
  final List<CardSummary> items;
  final int total;

  const SearchPage(this.items, this.total);
}

class PrintingInfo {
  final String id;
  final String setCode;
  final String setName;
  final String collectorNumber;
  final String rarityName;
  final String lang;
  final String? imageSmall;
  final String? imageNormal;
  final String? artist;

  const PrintingInfo({
    required this.id,
    required this.setCode,
    required this.setName,
    required this.collectorNumber,
    required this.rarityName,
    required this.lang,
    required this.imageSmall,
    required this.imageNormal,
    required this.artist,
  });
}

class RulingInfo {
  final String publishedAt;
  final String comment;

  const RulingInfo(this.publishedAt, this.comment);
}

class CardDetail {
  final String oracleId;
  final String name;
  final int legalities;
  final Map<String, dynamic> rawJson; // preferred (or requested) print
  final List<PrintingInfo> printings;
  final List<RulingInfo> rulings;

  const CardDetail({
    required this.oracleId,
    required this.name,
    required this.legalities,
    required this.rawJson,
    required this.printings,
    required this.rulings,
  });
}

const _rarityNames = ['common', 'uncommon', 'rare', 'special', 'mythic', 'bonus'];

class CardRepository {
  final AppDatabase db;

  CardRepository(this.db);

  Future<SearchPage> search(CompiledQuery query,
      {required int limit, required int offset}) async {
    final vars = [for (final p in query.params) Variable(p)];
    final rows = await db.customSelect(
      'SELECT cards.oracle_id, cards.name, cards.mana_cost, cards.type_line, '
      'p.image_uri_small, p.image_uri_normal '
      'FROM cards LEFT JOIN prints p ON p.id = cards.preferred_print_id '
      'WHERE ${query.where} ORDER BY ${query.orderBy} '
      'LIMIT $limit OFFSET $offset',
      variables: vars,
    ).get();
    final total = offset == 0 || rows.isNotEmpty
        ? (await db.customSelect(query.countSql(),
                variables: [for (final p in query.params) Variable(p)])
            .getSingle())
            .data['n'] as int
        : 0;
    return SearchPage(
      [
        for (final r in rows)
          CardSummary(
            oracleId: r.data['oracle_id'] as String,
            name: r.data['name'] as String,
            manaCost: r.data['mana_cost'] as String?,
            typeLine: r.data['type_line'] as String,
            imageSmall: r.data['image_uri_small'] as String?,
            imageNormal: r.data['image_uri_normal'] as String?,
          )
      ],
      total,
    );
  }

  Future<CardDetail?> detail(String oracleId, {String? printId}) async {
    final card = await db.customSelect(
        'SELECT oracle_id, name, legalities, preferred_print_id FROM cards '
        'WHERE oracle_id = ?',
        variables: [Variable(oracleId)]).getSingleOrNull();
    if (card == null) return null;

    final printRows = await db.customSelect(
        'SELECT * FROM prints WHERE oracle_id = ? ORDER BY released_at DESC',
        variables: [Variable(oracleId)]).get();
    final rulingRows = await db.customSelect(
        'SELECT published_at, comment FROM rulings WHERE oracle_id = ? '
        'ORDER BY published_at',
        variables: [Variable(oracleId)]).get();

    final selectedId =
        printId ?? card.data['preferred_print_id'] as String?;
    final selected = printRows.where((r) => r.data['id'] == selectedId).toList();
    final rawRow = selected.isNotEmpty ? selected.first : printRows.first;

    return CardDetail(
      oracleId: oracleId,
      name: card.data['name'] as String,
      legalities: card.data['legalities'] as int,
      rawJson: jsonDecode(rawRow.data['raw_json'] as String)
          as Map<String, dynamic>,
      printings: [
        for (final r in printRows)
          PrintingInfo(
            id: r.data['id'] as String,
            setCode: r.data['set_code'] as String,
            setName: r.data['set_name'] as String,
            collectorNumber: r.data['collector_number'] as String,
            rarityName: _rarityNames[(r.data['rarity'] as int)
                .clamp(0, _rarityNames.length - 1)],
            lang: r.data['lang'] as String,
            imageSmall: r.data['image_uri_small'] as String?,
            imageNormal: r.data['image_uri_normal'] as String?,
            artist: r.data['artist'] as String?,
          )
      ],
      rulings: [
        for (final r in rulingRows)
          RulingInfo(
              r.data['published_at'] as String, r.data['comment'] as String)
      ],
    );
  }

  Future<Map<String, String>> metaEntries() async {
    final rows = await db.customSelect('SELECT key, value FROM meta').get();
    return {
      for (final r in rows) r.data['key'] as String: r.data['value'] as String
    };
  }

  /// Distinct sets for the filter sheet's set autocomplete.
  Future<List<(String, String)>> allSets() async {
    final rows = await db.customSelect(
        'SELECT DISTINCT set_code, set_name FROM prints ORDER BY set_name').get();
    return [
      for (final r in rows)
        (r.data['set_code'] as String, r.data['set_name'] as String)
    ];
  }
}
