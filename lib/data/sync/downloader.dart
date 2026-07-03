import 'dart:io';

import 'package:http/http.dart' as http;

/// Streams [uri] to [target], reporting received bytes. Downloads land in a
/// `.part` file first so an interrupted transfer never looks complete.
Future<void> downloadFile(
  http.Client client,
  Uri uri,
  File target, {
  required Map<String, String> headers,
  void Function(int received, int? total)? onProgress,
}) async {
  final request = http.Request('GET', uri)..headers.addAll(headers);
  final response = await client.send(request);
  if (response.statusCode != 200) {
    throw http.ClientException(
        'download of $uri failed: HTTP ${response.statusCode}', uri);
  }

  final part = File('${target.path}.part');
  part.parent.createSync(recursive: true);
  final sink = part.openWrite();
  var received = 0;
  try {
    await for (final chunk in response.stream) {
      received += chunk.length;
      sink.add(chunk);
      onProgress?.call(received, response.contentLength);
    }
    await sink.flush();
  } finally {
    await sink.close();
  }
  if (target.existsSync()) target.deleteSync();
  part.renameSync(target.path);
}
