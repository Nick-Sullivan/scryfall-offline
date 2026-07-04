@Timeout(Duration(minutes: 30))
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:scryfall_app/data/db/database.dart';
import 'package:scryfall_app/data/repo/card_repository.dart';
import 'package:scryfall_app/data/sync/bulk_line_decoder.dart';
import 'package:scryfall_app/data/sync/ingestor.dart';
import 'package:scryfall_app/search/compiler/sql_compiler.dart';
import 'package:scryfall_app/search/parser/grammar.dart';

import '../helpers/test_db.dart';

// Ad-hoc profiling against the full Scryfall bulk file. Skipped unless
// SCRYFALL_BULK_JSON points at a downloaded default_cards bulk file:
//   SCRYFALL_BULK_JSON=path\to\default-cards.json \
//     flutter test test/perf/search_perf_test.dart
// The ingested database is cached next to the bulk file for re-runs.
final _bulkPath = Platform.environment['SCRYFALL_BULK_JSON'];
final _bulk = File(_bulkPath ?? '');
final _dbFile = File('${_bulkPath ?? ''}.perf.db');

void main() {
  configureSqliteForTests();

  test('profile representative filter queries', () async {
    if (_bulkPath == null || !_bulk.existsSync()) {
      markTestSkipped('SCRYFALL_BULK_JSON not set or missing');
      return;
    }

    if (!_dbFile.existsSync()) {
      final sw = Stopwatch()..start();
      final db = AppDatabase.local(file: _dbFile, staging: true);
      final ingestor = Ingestor(db);
      await ingestor.ingestCards(_bulk
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .transform(const BulkLineDecoder()));
      await ingestor.finalize();
      await db.close();
      stdout.writeln('ingest took ${sw.elapsed}');
    }

    final db = AppDatabase.local(file: _dbFile);
    final repo = CardRepository(db);
    final counts = await db.customSelect(
        'SELECT (SELECT COUNT(*) FROM cards) c, '
        '(SELECT COUNT(*) FROM prints) p, '
        '(SELECT COUNT(*) FROM faces) f').getSingle();
    stdout.writeln('cards=${counts.data['c']} prints=${counts.data['p']} '
        'faces=${counts.data['f']}');

    const queries = [
      '',
      't:creature',
      'c:g',
      't:creature c:g',
      'f:commander',
      '(r:rare or r:mythic)',
      'o:"draw a card"',
      'id:wub',
      't:creature c:g f:commander mv>=2 mv<=5',
      't:legendary t:elf',
    ];

    for (final q in queries) {
      final compiled = q.isEmpty
          ? const CompiledQuery('1=1', [], 'cards.name COLLATE NOCASE ASC')
          : SqlCompiler.compile(ScryfallQueryParser.parse(q));

      var sw = Stopwatch()..start();
      final rows = await repo.searchRows(compiled, limit: 60, offset: 0);
      final pageMs = sw.elapsedMilliseconds;

      sw = Stopwatch()..start();
      final total = await repo.count(compiled);
      final countMs = sw.elapsedMilliseconds;

      stdout.writeln(
          '${'"$q"'.padRight(46)} page=${'${pageMs}ms'.padRight(8)} '
          'count=${'${countMs}ms'.padRight(8)} '
          'rows=${rows.length} total=$total');

      final plan = await db.customSelect(
          'EXPLAIN QUERY PLAN SELECT cards.oracle_id FROM cards '
          'LEFT JOIN prints p ON p.id = cards.preferred_print_id '
          'WHERE ${compiled.where} ORDER BY ${compiled.orderBy} LIMIT 60',
          variables: [
            for (final v in compiled.params) Variable(v)
          ]).get();
      for (final r in plan) {
        stdout.writeln('    plan: ${r.data['detail']}');
      }
    }

    await db.close();
  });
}
