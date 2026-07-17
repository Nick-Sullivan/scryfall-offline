import 'dart:async';

import 'package:drift/drift.dart';

import 'tag_database.dart';

class TagIngestStats {
  int tags = 0;
  int taggings = 0;
}

/// Pure ingest core for the `oracle_tags` bulk file: consumes decoded tag
/// objects and writes batched rows into [db]. Platform-independent so the
/// whole pipeline runs on the Dart VM in tests; isolate/file plumbing lives
/// in tag_ingest_isolate.dart.
class TagIngestor {
  static const _batchSize = 800;

  final TagDatabase db;
  final void Function(int processed)? onProgress;

  final _stats = TagIngestStats();

  TagIngestor(this.db, {this.onProgress});

  TagIngestStats get stats => _stats;

  Future<void> ingestTags(Stream<Map<String, dynamic>> objects) async {
    var tags = <TagsCompanion>[];
    var aliases = <TagAliasesCompanion>[];
    var edges = <TagEdgesCompanion>[];
    var cards = <TagCardsCompanion>[];
    var processed = 0;

    Future<void> flush() async {
      if (tags.isEmpty) return;
      final t = tags, a = aliases, e = edges, c = cards;
      tags = [];
      aliases = [];
      edges = [];
      cards = [];
      await db.batch((b) {
        b.insertAll(db.tags, t, mode: InsertMode.insertOrReplace);
        b.insertAll(db.tagAliases, a, mode: InsertMode.insertOrReplace);
        b.insertAll(db.tagEdges, e, mode: InsertMode.insertOrReplace);
        b.insertAll(db.tagCards, c, mode: InsertMode.insertOrReplace);
      });
    }

    await for (final json in objects) {
      if (json['object'] != 'tag' || json['type'] != 'oracle') continue;
      final id = json['id'] as String?;
      final slug = json['slug'] as String?;
      if (id == null || slug == null) continue;

      tags.add(TagsCompanion.insert(
        id: id,
        slug: normalizeTag(slug),
        label: json['label'] as String? ?? slug,
        description: Value(json['description'] as String?),
      ));
      _stats.tags++;

      for (final alias in (json['aliases'] as List? ?? const [])) {
        if (alias is! String || alias.isEmpty) continue;
        aliases.add(TagAliasesCompanion.insert(
            alias: normalizeTag(alias), tagId: id));
      }
      // parent_ids carry the whole hierarchy; child_ids are the same edges
      // seen from the other side.
      for (final parent in (json['parent_ids'] as List? ?? const [])) {
        if (parent is! String || parent.isEmpty) continue;
        edges.add(TagEdgesCompanion.insert(parentId: parent, childId: id));
      }
      for (final tagging in (json['taggings'] as List? ?? const [])) {
        final oracleId =
            (tagging as Map<String, dynamic>)['oracle_id'] as String?;
        if (oracleId == null) continue;
        cards.add(TagCardsCompanion.insert(tagId: id, oracleId: oracleId));
        _stats.taggings++;
      }

      processed++;
      if (tags.length >= _batchSize) {
        await flush();
        onProgress?.call(processed);
      }
    }
    await flush();
    onProgress?.call(processed);
  }

  Future<void> finalize({String? bulkUpdatedAt}) async {
    await db.customStatement('ANALYZE');
    final entries = {
      TagPackMetaKeys.fetchedAt: DateTime.now().toUtc().toIso8601String(),
      TagPackMetaKeys.tagCount: '${_stats.tags}',
      TagPackMetaKeys.taggingCount: '${_stats.taggings}',
      if (bulkUpdatedAt != null) TagPackMetaKeys.bulkUpdatedAt: bulkUpdatedAt,
    };
    await db.batch((b) => b.insertAll(
        db.tagPackMeta,
        [
          for (final e in entries.entries)
            TagPackMetaCompanion.insert(key: e.key, value: e.value)
        ],
        mode: InsertMode.insertOrReplace));
  }
}
