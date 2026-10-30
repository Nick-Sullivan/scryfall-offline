import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';

/// A folder the user granted through Android's folder picker: the persisted
/// tree uri plus its display name for messages and Settings.
typedef ArtFolder = ({String uri, String name});

/// Readable location of a picked folder, e.g. "Pictures/Scryfall". On-device
/// storage tree ids look like "primary:Pictures/Scryfall"; other providers
/// (Drive, SD-card apps) use opaque ids, so those fall back to the folder's
/// display name.
String artFolderPath(ArtFolder folder) {
  final uri = Uri.parse(folder.uri);
  if (uri.authority == 'com.android.externalstorage.documents' &&
      uri.pathSegments.length >= 2) {
    final id = uri.pathSegments[1]; // already percent-decoded
    final colon = id.indexOf(':');
    if (colon >= 0 && colon < id.length - 1) return id.substring(colon + 1);
  }
  return folder.name;
}

/// The picked folder was deleted or its grant revoked; the user has to
/// choose it again.
class ArtFolderLostException implements Exception {}

const _channel = MethodChannel('scryfall_app/art_folder');

/// Android folder picker and grant check (MainActivity's art_folder channel).
class ArtFolderChannel {
  /// Opens the picker in [current] when given, otherwise in Pictures.
  static Future<ArtFolder?> pickFolder({ArtFolder? current}) async {
    final r = await _channel.invokeMapMethod<String, String>(
        'pickFolder', {'current': current?.uri});
    return r == null ? null : (uri: r['uri']!, name: r['name']!);
  }

  static Future<bool> hasAccess(String uri) async =>
      await _channel.invokeMethod<bool>('hasAccess', {'uri': uri}) ?? false;
}

/// Where "Download all art" writes. Android saves into a user-picked folder
/// and overwrites same-named files; iOS Photos has no folders, so it adds to
/// an album instead.
abstract class ArtSaver {
  /// Shown in messages: "Saved 3 images to <label>".
  String get label;

  /// File names already present, so the confirm dialog can say how many
  /// will be replaced.
  Future<Set<String>> existingNames();

  /// Saves [png] as `<name>.png`, replacing a file of that name.
  Future<void> save(String name, Uint8List png);

  /// Opens the destination in a file or gallery app; false if none can.
  Future<bool> open();
}

/// The platform's saver: null on Android until a folder has been picked.
ArtSaver? artSaverFor(ArtFolder? folder) => Platform.isAndroid
    ? (folder == null ? null : SafArtSaver(folder))
    : GalleryArtSaver();

class SafArtSaver implements ArtSaver {
  final ArtFolder folder;

  SafArtSaver(this.folder);

  /// File name → document uri, listed once and kept current as files are
  /// written. Memoized as a Future so concurrent first saves share one list.
  late final Future<Map<String, String>> _docs = _guard(() async =>
      await _channel.invokeMapMethod<String, String>(
          'listFiles', {'uri': folder.uri}) ??
      {});

  @override
  String get label => artFolderPath(folder);

  @override
  Future<Set<String>> existingNames() async => (await _docs).keys.toSet();

  @override
  Future<void> save(String name, Uint8List png) async {
    final file = '$name.png';
    final docs = await _docs;
    final uri = await _guard(() => _channel.invokeMethod<String>('writeFile', {
          'uri': folder.uri,
          'name': file,
          'existing': docs[file],
          'bytes': png,
        }));
    if (uri != null) docs[file] = uri;
  }

  @override
  Future<bool> open() async =>
      await _channel.invokeMethod<bool>('openFolder', {'uri': folder.uri}) ??
      false;

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (e) {
      if (e.code == 'NO_ACCESS') throw ArtFolderLostException();
      rethrow;
    }
  }
}

class GalleryArtSaver implements ArtSaver {
  static const album = 'Scryfall';

  @override
  String get label => 'the $album album';

  @override
  Future<Set<String>> existingNames() async => const {};

  @override
  Future<void> save(String name, Uint8List png) =>
      Gal.putImageBytes(png, album: album, name: name);

  @override
  Future<bool> open() async {
    await Gal.open();
    return true;
  }
}
