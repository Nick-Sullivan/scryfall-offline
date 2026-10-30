import 'dart:convert';

import 'package:drift/drift.dart';

import '../../search/compiler/sql_compiler.dart';
import '../db/database.dart';

/// One search-result tile (oracle grain + the images of the print it shows:
/// the preferred print, or one matching an `atag:` search), or with
/// `unique:prints` one printing.
class CardSummary {
  final String oracleId;

  /// The print whose images these are; null if the card has none.
  final String? printId;

  /// Whether [printId] is the card's preferred print — the only one a
  /// legacy (oracle-keyed) offline image can stand in for.
  final bool isPreferredPrint;
  final String name;
  final String? manaCost;
  final String typeLine;
  final String? imageSmall;
  final String? imageNormal;

  const CardSummary({
    required this.oracleId,
    this.printId,
    this.isPreferredPrint = true,
    required this.name,
    required this.manaCost,
    required this.typeLine,
    required this.imageSmall,
    required this.imageNormal,
  });
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
  final bool isPreferredPrint; // whether rawJson is the preferred print
  final List<PrintingInfo> printings;
  final List<RulingInfo> rulings;

  const CardDetail({
    required this.oracleId,
    required this.name,
    required this.legalities,
    required this.rawJson,
    required this.isPreferredPrint,
    required this.printings,
    required this.rulings,
  });
}

/// One full-card image to export: PNG URL plus a gallery-friendly name
/// (no extension — the gallery plugin adds it).
class ArtTarget {
  final String url;
  final String name;

  const ArtTarget(this.url, this.name);
}

/// Scryfall's CDN keeps every size at the same path under a different
/// leading segment, so a stored 'normal' URL maps directly to the PNG:
/// `.../normal/front/a/b/<id>.jpg?123` → `.../png/front/a/b/<id>.png?123`
String pngUrl(String normalUrl) {
  final uri = Uri.parse(normalUrl);
  final segments = [...uri.pathSegments];
  if (segments.isNotEmpty) segments[0] = 'png';
  final last = segments.last;
  segments[segments.length - 1] = last.endsWith('.jpg')
      ? '${last.substring(0, last.length - 4)}.png'
      : last;
  return uri.replace(pathSegments: segments).toString();
}

String _safeFileName(String s) =>
    s.replaceAll(' // ', ' - ').replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');

const _rarityNames = [
  'common',
  'uncommon',
  'rare',
  'special',
  'mythic',
  'bonus',
];

class CardRepository {
  final AppDatabase db;

  CardRepository(this.db);

  static const _summaryColumns =
      'cards.oracle_id, cards.name, cards.mana_cost, cards.type_line, '
      'p.id AS print_id, p.id IS cards.preferred_print_id AS is_preferred, '
      'p.image_uri_small, p.image_uri_normal';

  static CardSummary _summary(QueryRow r) => CardSummary(
    oracleId: r.data['oracle_id'] as String,
    printId: r.data['print_id'] as String?,
    isPreferredPrint: r.data['is_preferred'] == 1,
    name: r.data['name'] as String,
    manaCost: r.data['mana_cost'] as String?,
    typeLine: r.data['type_line'] as String,
    imageSmall: r.data['image_uri_small'] as String?,
    imageNormal: r.data['image_uri_normal'] as String?,
  );

  /// One page of matching cards. Kept separate from [count] so the UI can
  /// paint results without waiting on the full-table COUNT(*).
  Future<List<CardSummary>> searchRows(
    CompiledQuery query, {
    required int limit,
    required int offset,
  }) async {
    final shown = switch (query.displayPrint) {
      final display? => 'COALESCE($display, cards.preferred_print_id)',
      null => 'cards.preferred_print_id',
    };
    // Prints mode already has one print per row (alias p).
    final from = query.prints
        ? query.from
        : 'cards LEFT JOIN prints p ON p.id = $shown';
    final rows = await db
        .customSelect(
          'SELECT $_summaryColumns '
          'FROM $from '
          'WHERE ${query.where} ORDER BY ${query.orderBy} '
          'LIMIT $limit OFFSET $offset',
          variables: [
            for (final p in [...query.displayParams, ...query.params])
              Variable(p),
          ],
        )
        .get();
    return [for (final r in rows) _summary(r)];
  }

  /// Summaries for [oracleIds], returned in the same order (missing ids —
  /// e.g. a card gone after a data update — are silently dropped). Chunked
  /// to stay under SQLite's bind-variable limit.
  Future<List<CardSummary>> summariesByIds(List<String> oracleIds) async {
    final found = <String, CardSummary>{};
    for (var i = 0; i < oracleIds.length; i += 500) {
      final chunk = oracleIds.sublist(
        i,
        i + 500 > oracleIds.length ? oracleIds.length : i + 500,
      );
      final rows = await db
          .customSelect(
            'SELECT $_summaryColumns '
            'FROM cards LEFT JOIN prints p ON p.id = cards.preferred_print_id '
            'WHERE cards.oracle_id IN (${List.filled(chunk.length, '?').join(',')})',
            variables: [for (final id in chunk) Variable(id)],
          )
          .get();
      for (final r in rows) {
        final s = _summary(r);
        found[s.oracleId] = s;
      }
    }
    return [
      for (final id in oracleIds)
        if (found[id] case final s?) s,
    ];
  }

  /// Total matching cards (a full scan with EXISTS subqueries — the slow part
  /// of a search, run after results are already on screen).
  Future<int> count(CompiledQuery query) async {
    final row = await db
        .customSelect(
          query.countSql(),
          variables: [for (final p in query.params) Variable(p)],
        )
        .getSingle();
    return row.data['n'] as int;
  }

  Future<CardDetail?> detail(String oracleId, {String? printId}) async {
    final card = await db
        .customSelect(
          'SELECT oracle_id, name, legalities, preferred_print_id FROM cards '
          'WHERE oracle_id = ?',
          variables: [Variable(oracleId)],
        )
        .getSingleOrNull();
    if (card == null) return null;

    // raw_json is a few KB per row and heavily reprinted cards (basic lands)
    // have hundreds of printings — fetch it only for the print we display.
    final printRows = await db
        .customSelect(
          'SELECT id, set_code, set_name, collector_number, rarity, lang, '
          'image_uri_small, image_uri_normal, artist '
          'FROM prints WHERE oracle_id = ? ORDER BY released_at DESC',
          variables: [Variable(oracleId)],
        )
        .get();
    final rulingRows = await db
        .customSelect(
          'SELECT published_at, comment FROM rulings WHERE oracle_id = ? '
          'ORDER BY published_at',
          variables: [Variable(oracleId)],
        )
        .get();

    final selectedId = printId ?? card.data['preferred_print_id'] as String?;
    final selected = printRows.any((r) => r.data['id'] == selectedId)
        ? selectedId!
        : printRows.first.data['id'] as String;
    final rawRow = await db
        .customSelect(
          'SELECT raw_json FROM prints WHERE id = ?',
          variables: [Variable(selected)],
        )
        .getSingle();

    return CardDetail(
      oracleId: oracleId,
      name: card.data['name'] as String,
      legalities: card.data['legalities'] as int,
      rawJson:
          jsonDecode(rawRow.data['raw_json'] as String) as Map<String, dynamic>,
      isPreferredPrint: selected == card.data['preferred_print_id'],
      printings: [
        for (final r in printRows)
          PrintingInfo(
            id: r.data['id'] as String,
            setCode: r.data['set_code'] as String,
            setName: r.data['set_name'] as String,
            collectorNumber: r.data['collector_number'] as String,
            rarityName:
                _rarityNames[(r.data['rarity'] as int).clamp(
                  0,
                  _rarityNames.length - 1,
                )],
            lang: r.data['lang'] as String,
            imageSmall: r.data['image_uri_small'] as String?,
            imageNormal: r.data['image_uri_normal'] as String?,
            artist: r.data['artist'] as String?,
          ),
      ],
      rulings: [
        for (final r in rulingRows)
          RulingInfo(
            r.data['published_at'] as String,
            r.data['comment'] as String,
          ),
      ],
    );
  }

  Future<Map<String, String>> metaEntries() async {
    final rows = await db.customSelect('SELECT key, value FROM meta').get();
    return {
      for (final r in rows) r.data['key'] as String: r.data['value'] as String,
    };
  }

  Future<void> setMetaEntry(String key, String value) => db
      .into(db.meta)
      .insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));

  /// (print id, normal-image URL) for the offline image pack: each card's
  /// preferred print, or every print when [allPrints]. DFC prints carry the
  /// front face's image here.
  Future<List<(String, String)>> imageTargets({required bool allPrints}) async {
    final rows = await db
        .customSelect(
          allPrints
              ? 'SELECT p.id, p.image_uri_normal FROM prints p '
                    'WHERE p.image_uri_normal IS NOT NULL'
              : 'SELECT p.id, p.image_uri_normal FROM cards '
                    'JOIN prints p ON p.id = cards.preferred_print_id '
                    'WHERE p.image_uri_normal IS NOT NULL',
        )
        .get();
    return [
      for (final r in rows)
        (r.data['id'] as String, r.data['image_uri_normal'] as String),
    ];
  }

  /// oracle_id → preferred print id, for migrating an oracle-keyed image
  /// pack to print ids.
  Future<Map<String, String>> preferredPrintIds() async {
    final rows = await db
        .customSelect(
          'SELECT oracle_id, preferred_print_id FROM cards '
          'WHERE preferred_print_id IS NOT NULL',
        )
        .get();
    return {
      for (final r in rows)
        r.data['oracle_id'] as String: r.data['preferred_print_id'] as String,
    };
  }

  /// Full-card PNGs for every printing of one card, newest first, with a
  /// second entry per print for double-faced backs. The back's URL is only
  /// in raw_json (prints.image_uri_normal holds the front face).
  Future<List<ArtTarget>> artTargets(String oracleId) async {
    final rows = await db
        .customSelect(
          'SELECT c.name, p.set_code, p.collector_number, p.lang, '
          'p.image_uri_normal, '
          "json_extract(p.raw_json, '\$.card_faces[1].image_uris.normal') "
          'AS back_normal '
          'FROM prints p JOIN cards c ON c.oracle_id = p.oracle_id '
          'WHERE p.oracle_id = ? ORDER BY p.released_at DESC',
          variables: [Variable(oracleId)],
        )
        .get();
    final targets = <ArtTarget>[];
    for (final r in rows) {
      final lang = r.data['lang'] as String;
      final base = _safeFileName(
        '${r.data['name']} - '
        '${(r.data['set_code'] as String).toUpperCase()} '
        '${r.data['collector_number']}${lang == 'en' ? '' : ' $lang'}',
      );
      if (r.data['image_uri_normal'] case final String front) {
        targets.add(ArtTarget(pngUrl(front), base));
      }
      if (r.data['back_normal'] case final String back) {
        targets.add(ArtTarget(pngUrl(back), '$base (back)'));
      }
    }
    return targets;
  }

  /// Distinct type words for the filter sheet's type autocomplete, extracted
  /// from every type line ("Legendary Creature — Elf Warrior" contributes
  /// Legendary, Creature, Elf, Warrior). Face separators are dropped.
  Future<List<String>> allTypes() async {
    final rows = await db
        .customSelect('SELECT DISTINCT type_line FROM cards')
        .get();
    final types = <String>{};
    for (final r in rows) {
      for (final word in (r.data['type_line'] as String).split(
        RegExp(r'\s+'),
      )) {
        if (word.isNotEmpty && word != '—' && word != '//') types.add(word);
      }
    }
    return types.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Distinct sets for the filter sheet's set autocomplete.
  Future<List<(String, String)>> allSets() async {
    final rows = await db
        .customSelect(
          'SELECT DISTINCT set_code, set_name FROM prints ORDER BY set_name',
        )
        .get();
    return [
      for (final r in rows)
        (r.data['set_code'] as String, r.data['set_name'] as String),
    ];
  }

  /// Oracle tags (slug, label) on one card, alphabetical by label. Direct
  /// taggings only — the parent tags they roll up into aren't stored per card.
  /// Same tag-pack requirement as [allTags].
  Future<List<(String, String)>> tagsForCard(String oracleId) async {
    final rows = await db
        .customSelect(
          'SELECT t.slug, t.label FROM tagdb.tag_cards tc '
          'JOIN tagdb.tags t ON t.id = tc.tag_id '
          'WHERE tc.oracle_id = ? ORDER BY t.label',
          variables: [Variable(oracleId)],
        )
        .get();
    return [
      for (final r in rows)
        (r.data['slug'] as String, r.data['label'] as String),
    ];
  }

  /// Art tags (slug, label) on one printing's illustrations — every face of
  /// a double-faced print — alphabetical by label. Direct taggings only.
  /// Needs a tag pack with art tags (see artTagsInstalledProvider).
  Future<List<(String, String)>> artTagsForPrint(String printId) async {
    final rows = await db
        .customSelect(
          'SELECT DISTINCT t.slug, t.label FROM print_art pa '
          'JOIN tagdb.art_tag_illustrations ti '
          'ON ti.illustration_id = pa.illustration_id '
          'JOIN tagdb.art_tags t ON t.id = ti.tag_id '
          'WHERE pa.print_id = ? ORDER BY t.label',
          variables: [Variable(printId)],
        )
        .get();
    return [
      for (final r in rows)
        (r.data['slug'] as String, r.data['label'] as String),
    ];
  }

  /// Art tags (slug, label) for the filter sheet's art tag autocomplete.
  /// Same requirement as [artTagsForPrint].
  Future<List<(String, String)>> allArtTags() async {
    final rows = await db
        .customSelect('SELECT slug, label FROM tagdb.art_tags ORDER BY label')
        .get();
    return [
      for (final r in rows)
        (r.data['slug'] as String, r.data['label'] as String),
    ];
  }

  /// Oracle tags (slug, label) for the filter sheet's tag autocomplete. Only
  /// valid when the tag pack is attached — `tagdb` is unknown to SQLite
  /// otherwise, so callers must check first (see allTagsProvider).
  Future<List<(String, String)>> allTags() async {
    final rows = await db
        .customSelect('SELECT slug, label FROM tagdb.tags ORDER BY label')
        .get();
    return [
      for (final r in rows)
        (r.data['slug'] as String, r.data['label'] as String),
    ];
  }
}
