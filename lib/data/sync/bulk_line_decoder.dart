import 'dart:async';
import 'dart:convert';

/// Decodes Scryfall bulk downloads into one JSON object per event.
///
/// Handles both shapes Scryfall serves: a JSON array with one object per
/// line (`.json`: `[`, `  {...},`, `]`) and plain JSONL (`.jsonl`). Anything
/// that cleans to a non-object line is a hard error — bulk format drift
/// should fail loudly, not silently drop cards.
class BulkLineDecoder extends StreamTransformerBase<String, Map<String, dynamic>> {
  const BulkLineDecoder();

  @override
  Stream<Map<String, dynamic>> bind(Stream<String> lines) async* {
    var lineNo = 0;
    await for (final raw in lines) {
      lineNo++;
      var line = raw.trim();
      if (line.isEmpty || line == '[' || line == ']') continue;
      if (line.endsWith(',')) line = line.substring(0, line.length - 1);
      final Object? decoded;
      try {
        decoded = jsonDecode(line);
      } on FormatException catch (e) {
        throw FormatException(
            'Bulk data line $lineNo is not valid JSON: ${e.message}');
      }
      if (decoded is! Map<String, dynamic>) {
        throw FormatException(
            'Bulk data line $lineNo decoded to ${decoded.runtimeType}, '
            'expected a card object');
      }
      yield decoded;
    }
  }
}
