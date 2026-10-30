import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scryfall_app/app/providers.dart';
import 'package:scryfall_app/data/images/art_saver.dart';
import 'package:scryfall_app/data/repo/card_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records saves; throws [ArtFolderLostException] once [loseAfter] saves
/// have succeeded.
class _FakeSaver implements ArtSaver {
  final int? loseAfter;
  final saved = <String>[];

  _FakeSaver({this.loseAfter});

  @override
  String get label => 'fake';

  @override
  Future<Set<String>> existingNames() async => const {};

  @override
  Future<void> save(String name, Uint8List png) async {
    if (loseAfter != null && saved.length >= loseAfter!) {
      throw ArtFolderLostException();
    }
    saved.add(name);
  }

  @override
  Future<bool> open() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final targets = [
    for (var i = 0; i < 10; i++) ArtTarget('https://img/$i.png', 'card $i'),
  ];

  Future<ProviderContainer> makeContainer(http.Client client) async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        httpClientProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('artFolderPath shows on-device folders as a path', () {
    expect(
      artFolderPath((
        uri:
            'content://com.android.externalstorage.documents/tree/'
            'primary%3APictures%2FScryfall',
        name: 'Scryfall',
      )),
      'Pictures/Scryfall',
    );
    // Opaque provider ids (e.g. Drive) fall back to the display name.
    expect(
      artFolderPath((
        uri: 'content://com.google.android.apps.docs.storage/tree/abc123',
        name: 'MTG art',
      )),
      'MTG art',
    );
  });

  test('saves every image and counts failed downloads', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await makeContainer(
      MockClient(
        (req) async => req.url.path == '/3.png'
            ? http.Response('', 404)
            : http.Response.bytes([1, 2, 3], 200),
      ),
    );
    final saver = _FakeSaver();

    await container
        .read(artExportProvider.notifier)
        .start('oracle', targets, saver);

    final result = container.read(artExportProvider)!;
    expect(result.running, isFalse);
    expect(result.done, 9);
    expect(result.failed, 1);
    expect(saver.saved, isNot(contains('card 3')));
  });

  test('cancel stops new downloads from starting', () async {
    SharedPreferences.setMockInitialValues({});
    var requests = 0;
    late ProviderContainer container;
    container = await makeContainer(
      MockClient((req) async {
        if (++requests == 1) {
          container.read(artExportProvider.notifier).cancel();
        }
        return http.Response.bytes([1], 200);
      }),
    );

    await container
        .read(artExportProvider.notifier)
        .start('oracle', targets, _FakeSaver());

    // Only the workers already past their loop check finish their item.
    expect(requests, lessThanOrEqualTo(4));
    expect(container.read(artExportProvider)!.running, isFalse);
  });

  test('a lost folder stops the run and forgets the folder', () async {
    SharedPreferences.setMockInitialValues({
      'artFolderUri': 'content://tree/x',
      'artFolderName': 'MTG',
    });
    final container = await makeContainer(
      MockClient((req) async => http.Response.bytes([1], 200)),
    );
    expect(container.read(artFolderProvider)?.name, 'MTG');

    await container
        .read(artExportProvider.notifier)
        .start('oracle', targets, _FakeSaver(loseAfter: 2));

    final result = container.read(artExportProvider)!;
    expect(result.folderLost, isTrue);
    expect(result.done, 2);
    expect(result.done + result.failed, lessThan(targets.length));
    expect(container.read(artFolderProvider), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('artFolderUri'), isNull);
  });
}
