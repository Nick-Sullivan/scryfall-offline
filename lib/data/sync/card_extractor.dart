import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/colors.dart';
import '../../core/legalities.dart';
import '../../core/mana.dart';
import '../db/database.dart';
import '../db/tables.dart';

/// Layouts excluded from search entirely (Scryfall hides these "extras"
/// behind include:extras).
const Set<String> skippedLayouts = {
  'token',
  'double_faced_token',
  'emblem',
  'art_series',
};

/// Raw-JSON keys the app never reads; stripped before storage (~40% smaller).
const Set<String> _prunedKeys = {
  'prices',
  'purchase_uris',
  'related_uris',
  'multiverse_ids',
  'mtgo_id',
  'mtgo_foil_id',
  'tcgplayer_id',
  'tcgplayer_etched_id',
  'cardmarket_id',
  'arena_id',
  'image_status',
  'object',
  'uri',
  'scryfall_uri',
  'rulings_uri',
  'prints_search_uri',
  'set_uri',
  'set_search_uri',
  'scryfall_set_uri',
  'card_back_id',
  'illustration_id',
  'highres_image',
  'penny_rank',
  'preview',
};

const Set<String> _keptImageSizes = {'small', 'normal', 'art_crop'};

/// Rows extracted from one bulk card object.
class ExtractedCard {
  final CardsCompanion? card; // null when this oracle_id was already seen
  final List<FacesCompanion> faces;
  final PrintsCompanion print;

  ExtractedCard(this.card, this.faces, this.print);
}

class CardExtractor {
  final Set<String> _seenOracleIds = {};

  /// Returns null for skipped layouts or objects without an oracle identity.
  ExtractedCard? extract(Map<String, dynamic> json) {
    final layout = json['layout'] as String? ?? 'normal';
    if (skippedLayouts.contains(layout)) return null;

    final facesJson = (json['card_faces'] as List?)?.cast<Map<String, dynamic>>();
    final oracleId = json['oracle_id'] as String? ??
        facesJson?.first['oracle_id'] as String?;
    if (oracleId == null) return null;

    final print = _extractPrint(json, oracleId);
    if (_seenOracleIds.contains(oracleId)) {
      return ExtractedCard(null, const [], print);
    }
    _seenOracleIds.add(oracleId);

    final faces = _extractFaces(json, facesJson, oracleId);
    final colors = faces.fold<int>(0, (m, f) => m | f.colors.value);

    final card = CardsCompanion.insert(
      oracleId: oracleId,
      name: json['name'] as String? ?? '',
      cmc: _asDouble(json['cmc'] ?? facesJson?.first['cmc']) ?? 0,
      manaCost: Value(_wholeCardManaCost(json, facesJson)),
      typeLine: json['type_line'] as String? ??
          facesJson?.map((f) => f['type_line'] ?? '').join(' // ') ??
          '',
      colors: colors,
      colorIdentity: maskFromJsonColors(json['color_identity'] as List?),
      producedMana: maskFromJsonColors(json['produced_mana'] as List?),
      colorCount: colorCount(colors),
      keywordsPipe: _pipeJoin(json['keywords'] as List?),
      reserved: json['reserved'] as bool? ?? false,
      edhrecRank: Value(json['edhrec_rank'] as int?),
      layout: layout,
      legalities: packLegalities(json['legalities'] as Map<String, dynamic>?),
      releasedAtFirst: _julianDay(json['released_at'] as String?),
    );
    return ExtractedCard(card, faces, print);
  }

  List<FacesCompanion> _extractFaces(Map<String, dynamic> json,
      List<Map<String, dynamic>>? facesJson, String oracleId) {
    final sources = facesJson ?? [json];
    final topColors = maskFromJsonColors(json['colors'] as List?);
    return [
      for (var i = 0; i < sources.length; i++)
        _face(sources[i], oracleId, i, topColors),
    ];
  }

  FacesCompanion _face(
      Map<String, dynamic> f, String oracleId, int index, int fallbackColors) {
    final manaCost = f['mana_cost'] as String?;
    final pow = f['power'] as String?;
    final tou = f['toughness'] as String?;
    final loy = f['loyalty'] as String?;
    return FacesCompanion.insert(
      oracleId: oracleId,
      faceIndex: index,
      name: f['name'] as String? ?? '',
      manaCost: Value(manaCost),
      manaPips: (manaCost == null || manaCost.isEmpty)
          ? ''
          : parseManaCost(manaCost)?.encode() ?? '',
      typeLine: f['type_line'] as String? ?? '',
      oracleText: f['oracle_text'] as String? ?? '',
      colors: f['colors'] != null
          ? maskFromJsonColors(f['colors'] as List)
          : fallbackColors,
      powText: Value(pow),
      powNum: Value(_statValue(pow)),
      touText: Value(tou),
      touNum: Value(_statValue(tou)),
      loyText: Value(loy),
      loyNum: Value(_statValue(loy)),
    );
  }

  PrintsCompanion _extractPrint(Map<String, dynamic> json, String oracleId) {
    final finishes = (json['finishes'] as List?)?.cast<String>() ?? const [];
    var flags = 0;
    if (json['promo'] == true) flags |= PrintFlag.promo;
    if (json['full_art'] == true) flags |= PrintFlag.fullArt;
    if (json['digital'] == true) flags |= PrintFlag.digital;
    if (json['reprint'] == true) flags |= PrintFlag.reprint;
    if (finishes.contains('foil')) flags |= PrintFlag.foil;
    if (finishes.contains('nonfoil')) flags |= PrintFlag.nonfoil;
    if (finishes.contains('etched')) flags |= PrintFlag.etched;
    if (json['oversized'] == true) flags |= PrintFlag.oversized;
    if (json['textless'] == true) flags |= PrintFlag.textless;
    if (json['booster'] == true) flags |= PrintFlag.booster;
    if (json['image_status'] == 'highres_scan') flags |= PrintFlag.highres;

    var games = 0;
    for (final g in (json['games'] as List?) ?? const []) {
      games |= switch (g) {
        'paper' => GameFlag.paper,
        'arena' => GameFlag.arena,
        'mtgo' => GameFlag.mtgo,
        _ => 0,
      };
    }

    final images = json['image_uris'] as Map<String, dynamic>? ??
        ((json['card_faces'] as List?)?.first as Map<String, dynamic>?)?[
            'image_uris'] as Map<String, dynamic>?;

    return PrintsCompanion.insert(
      id: json['id'] as String,
      oracleId: oracleId,
      setCode: json['set'] as String? ?? '',
      setName: json['set_name'] as String? ?? '',
      collectorNumber: json['collector_number'] as String? ?? '',
      rarity: rarityOrdinal[json['rarity']] ?? 0,
      releasedAt: _julianDay(json['released_at'] as String?),
      lang: json['lang'] as String? ?? 'en',
      artist: Value(json['artist'] as String?),
      watermark: Value(json['watermark'] as String?),
      flavorText: Value(json['flavor_text'] as String?),
      frame: json['frame'] as String? ?? '',
      borderColor: json['border_color'] as String? ?? '',
      flags: flags,
      games: games,
      imageUriSmall: Value(images?['small'] as String?),
      imageUriNormal: Value(images?['normal'] as String?),
      rawJson: jsonEncode(_prune(json)),
    );
  }

  Map<String, dynamic> _prune(Map<String, dynamic> json) {
    final out = <String, dynamic>{};
    json.forEach((key, value) {
      if (_prunedKeys.contains(key)) return;
      if (key == 'image_uris' && value is Map<String, dynamic>) {
        out[key] = {
          for (final e in value.entries)
            if (_keptImageSizes.contains(e.key)) e.key: e.value
        };
      } else if (key == 'card_faces' && value is List) {
        out[key] = [
          for (final f in value.cast<Map<String, dynamic>>()) _prune(f)
        ];
      } else {
        out[key] = value;
      }
    });
    return out;
  }
}

String _pipeJoin(List<dynamic>? values) => values == null || values.isEmpty
    ? ''
    : '|${values.map((v) => (v as String).toLowerCase()).join('|')}|';

double? _asDouble(Object? v) => switch (v) {
      num n => n.toDouble(),
      _ => null,
    };

String? _wholeCardManaCost(
    Map<String, dynamic> json, List<Map<String, dynamic>>? faces) {
  final top = json['mana_cost'] as String?;
  if (top != null && top.isNotEmpty) return top;
  final parts = faces
      ?.map((f) => f['mana_cost'] as String? ?? '')
      .where((c) => c.isNotEmpty)
      .toList();
  return (parts == null || parts.isEmpty) ? top : parts.join(' // ');
}

/// Scryfall numeric semantics for pow/tou/loy: `*` counts as 0, `1+*` as 1.
double? _statValue(String? text) {
  if (text == null) return null;
  final cleaned = text.replaceAll('*', '').replaceAll('+', '').trim();
  if (cleaned.isEmpty || cleaned == '-') return 0;
  return double.tryParse(cleaned) ?? 0;
}

double _julianDay(String? isoDate) {
  if (isoDate == null) return 0;
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return 0;
  return dt.millisecondsSinceEpoch / Duration.millisecondsPerDay + 2440587.5;
}
