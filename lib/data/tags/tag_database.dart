import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'tag_database.g.dart';

/// Canonical form for tag lookup: Scryfall slugs are lowercase kebab-case,
/// so user input like `otag:"Grave Pact"` must fold to `grave-pact`.
String normalizeTag(String raw) =>
    raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');

/// One row per oracle tag from the `oracle_tags` bulk file.
class Tags extends Table {
  TextColumn get id => text()(); // Scryfall tag UUID
  TextColumn get slug => text()();
  TextColumn get label => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Alternate names; `otag:` matches these like the slug.
class TagAliases extends Table {
  TextColumn get alias => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {alias, tagId};
}

/// Tag hierarchy, built from each tag's `parent_ids`. `otag:x` includes all
/// descendants of x, resolved with a recursive CTE at query time.
class TagEdges extends Table {
  TextColumn get parentId => text()();
  TextColumn get childId => text()();

  @override
  Set<Column> get primaryKey => {parentId, childId};
}

/// Card membership (`taggings`). Weight is deliberately dropped — `otag:`
/// doesn't filter on it, and the pack is fully rebuilt on re-download.
class TagCards extends Table {
  TextColumn get tagId => text()();
  TextColumn get oracleId => text()();

  @override
  Set<Column> get primaryKey => {tagId, oracleId};
}

// Art tags (the `art_tags` bulk file) live in their own parallel tables rather
// than behind a kind column: slugs can repeat across the two vocabularies,
// and the otag: SQL stays untouched. They tag illustrations, not cards — the
// card DB's print_art maps illustrations back to prints and cards.

class ArtTags extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get label => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ArtTagAliases extends Table {
  TextColumn get alias => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {alias, tagId};
}

class ArtTagEdges extends Table {
  TextColumn get parentId => text()();
  TextColumn get childId => text()();

  @override
  Set<Column> get primaryKey => {parentId, childId};
}

class ArtTagIllustrations extends Table {
  TextColumn get tagId => text()();
  TextColumn get illustrationId => text()();

  @override
  Set<Column> get primaryKey => {tagId, illustrationId};
}

class TagPackMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class TagPackMetaKeys {
  static const fetchedAt = 'fetchedAt';
  static const bulkUpdatedAt = 'bulkUpdatedAt';
  static const tagCount = 'tagCount';
  static const taggingCount = 'taggingCount';

  /// Present only in packs built since art tags were added; its absence
  /// marks an older, oracle-only pack.
  static const artTagCount = 'artTagCount';
  static const artTaggingCount = 'artTaggingCount';
}

/// Schema owner for the optional tag pack (`tags.db`). Only the ingest
/// isolate and tests open it directly; the app reads it through an ATTACH
/// on the live card database's connections. Always built fresh in staging,
/// so schema bumps need no migration.
@DriftDatabase(tables: [
  Tags,
  TagAliases,
  TagEdges,
  TagCards,
  ArtTags,
  ArtTagAliases,
  ArtTagEdges,
  ArtTagIllustrations,
  TagPackMeta,
])
class TagDatabase extends _$TagDatabase {
  TagDatabase(super.e);

  factory TagDatabase.local({File? file, bool staging = false}) {
    final executor = file == null
        ? NativeDatabase.memory()
        : NativeDatabase(file, setup: (db) {
            if (staging) {
              // Disposable during ingest; deleted on any failure.
              db.execute('PRAGMA journal_mode = OFF;');
              db.execute('PRAGMA synchronous = OFF;');
            }
          });
    return TagDatabase(executor);
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE UNIQUE INDEX idx_tags_slug ON tags (slug)');
          await customStatement(
              'CREATE UNIQUE INDEX idx_art_tags_slug ON art_tags (slug)');
          // The detail screen looks tags up by illustration.
          await customStatement('CREATE INDEX idx_art_tag_illustrations_ill '
              'ON art_tag_illustrations (illustration_id)');
        },
      );
}
