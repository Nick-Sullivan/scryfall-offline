import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scryfall_app/data/sync/bulk_api.dart';

void main() {
  group('BulkApi.fetchSetsCardTotal', () {
    test('sums card_count across a single page', () async {
      final client = MockClient((req) async {
        expect(req.url.toString(), 'https://api.scryfall.com/sets');
        expect(req.headers['User-Agent'], contains('ScryfallApp/'));
        return http.Response(
            jsonEncode({
              'object': 'list',
              'has_more': false,
              'data': [
                {'code': 'aaa', 'card_count': 250},
                {'code': 'bbb', 'card_count': 100},
                {'code': 'ccc'}, // missing count tolerated
              ],
            }),
            200);
      });
      final api = BulkApi(client, appVersion: 'test');
      expect(await api.fetchSetsCardTotal(), 350);
    });

    test('follows next_page while has_more', () async {
      final client = MockClient((req) async {
        if (req.url.queryParameters['page'] == '2') {
          return http.Response(
              jsonEncode({
                'has_more': false,
                'data': [
                  {'card_count': 7},
                ],
              }),
              200);
        }
        return http.Response(
            jsonEncode({
              'has_more': true,
              'next_page': 'https://api.scryfall.com/sets?page=2',
              'data': [
                {'card_count': 3},
              ],
            }),
            200);
      });
      final api = BulkApi(client, appVersion: 'test');
      expect(await api.fetchSetsCardTotal(), 10);
    });

    test('throws on non-200', () async {
      final client = MockClient((req) async => http.Response('nope', 503));
      final api = BulkApi(client, appVersion: 'test');
      expect(api.fetchSetsCardTotal(), throwsA(isA<http.ClientException>()));
    });
  });

  group('BulkApi.fetchOracleTagsInfo', () {
    test('resolves the oracle_tags entry, preferring jsonl', () async {
      final client = MockClient((req) async {
        expect(req.url.toString(), 'https://api.scryfall.com/bulk-data');
        expect(req.headers['User-Agent'], contains('ScryfallApp/'));
        return http.Response(
            jsonEncode({
              'object': 'list',
              'data': [
                {
                  'type': 'default_cards',
                  'updated_at': '2026-07-17T21:11:17.183+00:00',
                  'size': 1,
                  'download_uri': 'https://data.scryfall.io/cards.json',
                },
                {
                  'type': 'oracle_tags',
                  'updated_at': '2026-07-17T21:00:36.823+00:00',
                  'size': 18119952,
                  'download_uri': 'https://data.scryfall.io/tags.json',
                  'jsonl_download_uri':
                      'https://data.scryfall.io/tags.jsonl.gz',
                },
              ],
            }),
            200);
      });
      final api = BulkApi(client, appVersion: 'test');
      final info = await api.fetchOracleTagsInfo();
      expect(info.type, 'oracle_tags');
      expect(info.downloadUri.toString(),
          'https://data.scryfall.io/tags.jsonl.gz');
      expect(info.isGzip, isTrue);
      expect(info.updatedAt, '2026-07-17T21:00:36.823+00:00');
    });

    test('throws when the entry is missing', () async {
      final client = MockClient((req) async => http.Response(
          jsonEncode({
            'object': 'list',
            'data': [
              {
                'type': 'default_cards',
                'updated_at': 'x',
                'size': 1,
                'download_uri': 'https://data.scryfall.io/cards.json',
              },
            ],
          }),
          200));
      final api = BulkApi(client, appVersion: 'test');
      expect(api.fetchOracleTagsInfo(), throwsA(isA<StateError>()));
    });
  });
}
