import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../core/mana.dart' as mana;
import 'tables.dart';

part 'database.g.dart';

const int schemaVersionValue = 1;

@DriftDatabase(tables: [Cards, Faces, Prints, Rulings, Meta])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens (or creates) the database at [file] with queries running on
  /// background isolates. The read pool lets slow queries (COUNT(*) of a
  /// broad search) run alongside detail/page queries instead of serializing
  /// them all on one connection; WAL is required for the pool to be used.
  factory AppDatabase.background(File file) =>
      AppDatabase(NativeDatabase.createInBackground(
        file,
        readPool: 4,
        setup: (db) {
          setupSqlite(db);
          db.execute('PRAGMA journal_mode = WAL;');
          db.execute('PRAGMA busy_timeout = 5000;');
        },
      ));

  /// Same-isolate open. Used for the staging database inside the ingest
  /// isolate and for tests ([file] null = in-memory).
  factory AppDatabase.local({File? file, bool staging = false}) {
    final executor = file == null
        ? NativeDatabase.memory(setup: setupSqlite)
        : NativeDatabase(file, setup: (db) {
            setupSqlite(db);
            if (staging) {
              // Disposable during ingest; deleted on any failure.
              db.execute('PRAGMA journal_mode = OFF;');
              db.execute('PRAGMA synchronous = OFF;');
            }
          });
    return AppDatabase(executor);
  }

  @override
  int get schemaVersion => schemaVersionValue;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await createSearchArtifacts();
        },
      );

  /// Indexes and external-content FTS5 tables (trigram tokenizer so that
  /// Scryfall-style substring matches use the index). Rebuilt wholesale
  /// after bulk ingest — no sync triggers needed.
  Future<void> createSearchArtifacts() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_faces_oracle ON faces (oracle_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_prints_oracle ON prints (oracle_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_prints_set ON prints (set_code)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_rulings_oracle ON rulings (oracle_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_cards_name ON cards (name COLLATE NOCASE)');
    await customStatement('CREATE VIRTUAL TABLE IF NOT EXISTS face_name_fts '
        "USING fts5(name, content='faces', content_rowid='id', tokenize='trigram')");
    await customStatement('CREATE VIRTUAL TABLE IF NOT EXISTS face_text_fts '
        "USING fts5(oracle_text, type_line, content='faces', content_rowid='id', tokenize='trigram')");
  }

  Future<void> rebuildFtsIndexes() async {
    await customStatement(
        "INSERT INTO face_name_fts(face_name_fts) VALUES('rebuild')");
    await customStatement(
        "INSERT INTO face_text_fts(face_text_fts) VALUES('rebuild')");
  }
}

/// Registers app-specific SQL functions on every new connection. Keeping
/// exotic operators (regex, mana multiset algebra) inside SQL preserves
/// correct LIMIT/OFFSET pagination and counts.
void setupSqlite(sqlite.Database db) {
  final regexCache = <String, RegExp?>{};

  db.createFunction(
    functionName: 'regexp',
    argumentCount: const sqlite.AllowedArgumentCount(2),
    deterministic: true,
    function: (args) {
      final pattern = args[0];
      final value = args[1];
      if (pattern is! String || value is! String) return false;
      final re = regexCache.putIfAbsent(pattern, () {
        if (regexCache.length > 64) regexCache.clear();
        try {
          return RegExp(pattern, caseSensitive: false);
        } on FormatException {
          return null;
        }
      });
      return re?.hasMatch(value) ?? false;
    },
  );

  void manaFn(String name, bool Function(String, String) impl) {
    db.createFunction(
      functionName: name,
      argumentCount: const sqlite.AllowedArgumentCount(2),
      deterministic: true,
      function: (args) {
        final a = args[0];
        final b = args[1];
        if (a is! String || b is! String) return false;
        return impl(a, b);
      },
    );
  }

  manaFn('mana_geq', mana.manaGeq);
  manaFn('mana_leq', mana.manaLeq);
  manaFn('mana_eq', mana.manaEq);
}
