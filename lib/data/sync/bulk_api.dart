import 'dart:convert';

import 'package:http/http.dart' as http;

/// Contact string Scryfall asks for in User-Agent; version is appended by
/// [scryfallHeaders].
const appContact = 'nicholas.sullivan@skutopia.com';

Map<String, String> scryfallHeaders(String appVersion) => {
      'User-Agent': 'ScryfallApp/$appVersion ($appContact)',
      'Accept': 'application/json',
    };

class BulkFileInfo {
  final String type;
  final String updatedAt;
  final int size; // uncompressed bytes, per API
  final Uri downloadUri; // .jsonl.gz when offered, else .json

  const BulkFileInfo({
    required this.type,
    required this.updatedAt,
    required this.size,
    required this.downloadUri,
  });

  bool get isGzip => downloadUri.path.endsWith('.gz');
}

class BulkDataIndex {
  final BulkFileInfo defaultCards;
  final BulkFileInfo rulings;

  const BulkDataIndex({required this.defaultCards, required this.rulings});
}

/// Resolves the daily bulk file URLs. api.scryfall.com is rate-limited
/// (10 rps) — this is one request, made at most a few times per day; the
/// data.scryfall.io downloads themselves are unmetered.
class BulkApi {
  final http.Client client;
  final String appVersion;

  BulkApi(this.client, {required this.appVersion});

  Future<BulkDataIndex> fetchIndex() async {
    final data = await _fetchEntries();
    return BulkDataIndex(
      defaultCards: _parseEntry(data, 'default_cards'),
      rulings: _parseEntry(data, 'rulings'),
    );
  }

  /// The `oracle_tags` bulk file (community Tagger data). Separate from
  /// [fetchIndex] so the card-sync path never depends on this entry existing.
  Future<BulkFileInfo> fetchOracleTagsInfo() async =>
      _parseEntry(await _fetchEntries(), 'oracle_tags');

  Future<List> _fetchEntries() async {
    final resp = await client.get(
      Uri.parse('https://api.scryfall.com/bulk-data'),
      headers: scryfallHeaders(appVersion),
    );
    if (resp.statusCode != 200) {
      throw http.ClientException(
          'bulk-data endpoint returned HTTP ${resp.statusCode}');
    }
    return (jsonDecode(resp.body) as Map<String, dynamic>)['data'] as List;
  }

  BulkFileInfo _parseEntry(List data, String type) {
    final entry = data.cast<Map<String, dynamic>>().firstWhere(
          (e) => e['type'] == type,
          orElse: () => throw StateError("bulk-data has no '$type' entry"),
        );
    final uri = entry['jsonl_download_uri'] as String? ??
        entry['download_uri'] as String;
    return BulkFileInfo(
      type: type,
      updatedAt: entry['updated_at'] as String,
      size: entry['size'] as int? ?? 0,
      downloadUri: Uri.parse(uri),
    );
  }

  /// Sums card_count across all sets — a cheap fingerprint of "how many
  /// cards exist upstream" that, unlike the bulk file's updated_at, doesn't
  /// change on Scryfall's twice-daily price-only regenerations.
  Future<int> fetchSetsCardTotal() async {
    var url = Uri.parse('https://api.scryfall.com/sets');
    var total = 0;
    while (true) {
      final resp = await client.get(url, headers: scryfallHeaders(appVersion));
      if (resp.statusCode != 200) {
        throw http.ClientException(
            'sets endpoint returned HTTP ${resp.statusCode}');
      }
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      for (final e in (body['data'] as List).cast<Map<String, dynamic>>()) {
        total += (e['card_count'] as num?)?.toInt() ?? 0;
      }
      // Unpaginated today, but the List envelope allows it.
      final next = body['next_page'] as String?;
      if (body['has_more'] != true || next == null) return total;
      url = Uri.parse(next);
    }
  }
}
