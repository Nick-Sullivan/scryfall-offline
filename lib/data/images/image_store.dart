import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// On-disk store of one 'normal' card image per oracle_id (the preferred
/// print's front image, ~100 KB each — ~3.3 GB for the full pool), letting
/// the app show cards without network. Lives outside the image cache so it
/// is never evicted; survives card-data updates and is deleted only from the
/// data screen.
class ImageStore {
  final Directory root; // <application support>/images

  ImageStore(this.root);

  File fileFor(String oracleId) => File(p.join(root.path, '$oracleId.jpg'));

  int countSync() =>
      root.existsSync() ? root.listSync().whereType<File>().length : 0;

  void deleteAll() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  }

  /// Downloads one image; returns false on any failure (caller counts and
  /// moves on — a re-run retries missing files). Writes via a temp file so
  /// an interrupted download never leaves a truncated image behind.
  Future<bool> download(
      http.Client client, String oracleId, String url) async {
    final tmp = File('${fileFor(oracleId).path}.part');
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode != 200) return false;
      tmp.writeAsBytesSync(response.bodyBytes);
      tmp.renameSync(fileFor(oracleId).path);
      return true;
    } catch (_) {
      if (tmp.existsSync()) tmp.deleteSync();
      return false;
    }
  }
}
