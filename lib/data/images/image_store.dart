import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// On-disk store of 'normal' card images keyed by print id (~100 KB each —
/// ~3.3 GB for one per card, ~10 GB for every print), letting the app show
/// cards without network. Lives outside the image cache so it is never
/// evicted; survives card-data updates and is deleted only from the data
/// screen.
///
/// Packs from before print keying hold one `<oracleId>.jpg` per card (its
/// preferred print); [fileFor] still reads those until [migrate] renames
/// them.
class ImageStore {
  final Directory root; // <application support>/images

  ImageStore(this.root);

  File _file(String id) => File(p.join(root.path, '$id.jpg'));

  /// The image for [printId]. Pass [legacyOracleId] only when this is the
  /// card's preferred print: an unmigrated `<oracleId>.jpg` holds that
  /// print's image and nothing else's.
  File fileFor(String printId, {String? legacyOracleId}) {
    final file = _file(printId);
    if (legacyOracleId == null || file.existsSync()) return file;
    final legacy = _file(legacyOracleId);
    return legacy.existsSync() ? legacy : file;
  }

  int countSync() =>
      root.existsSync() ? root.listSync().whereType<File>().length : 0;

  /// Ids of the stored images (file names minus `.jpg`).
  Future<Set<String>> storedIds() async {
    if (!root.existsSync()) return {};
    return {
      await for (final f in root.list())
        if (f is File && f.path.endsWith('.jpg'))
          p.basenameWithoutExtension(f.path),
    };
  }

  void deleteAll() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  }

  /// Renames legacy `<oracleId>.jpg` files to `<printId>.jpg` using
  /// [oracleToPrint] (each card's preferred print). Rename-only, so nothing
  /// is lost or re-downloaded, and safe to re-run after an interruption.
  /// Files with no mapping (cards gone after a data update) are left alone.
  Future<void> migrate(Map<String, String> oracleToPrint) async {
    for (final id in await storedIds()) {
      final printId = oracleToPrint[id];
      if (printId == null) continue;
      final target = _file(printId);
      if (target.existsSync()) {
        await _file(id).delete();
      } else {
        await _file(id).rename(target.path);
      }
    }
  }

  /// Downloads one image; returns false on any failure (caller counts and
  /// moves on — a re-run retries missing files). Writes via a temp file so
  /// an interrupted download never leaves a truncated image behind.
  Future<bool> download(http.Client client, String printId, String url) async {
    final tmp = File('${_file(printId).path}.part');
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode != 200) return false;
      tmp.writeAsBytesSync(response.bodyBytes);
      tmp.renameSync(_file(printId).path);
      return true;
    } catch (_) {
      if (tmp.existsSync()) tmp.deleteSync();
      return false;
    }
  }
}
