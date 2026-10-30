import 'dart:async';

import 'package:drift/drift.dart';

import 'tag_database.dart';

class TagIngestStats {
  int tags = 0;
  int taggings = 0;
  int artTags = 0;
  int artTaggings = 0;
}

/// Pure ingest core for the `oracle_tags` and `art_tags` bulk files: consumes
/// decoded tag objects of either kind and writes batched rows into [db]
/// (oracle tags to tags/tag_*, illustration tags to art_tags/art_tag_*).
/// Platform-independent so the whole pipeline runs on the Dart VM in tests;
/// isolate/file plumbing lives in tag_ingest_isolate.dart.
class TagIngestor {
  static const _batchSize = 800;

  final TagDatabase db;
  final void Function(int processed)? onProgress;

  final _stats = TagIngestStats();

  TagIngestor(this.db, {this.onProgress});

  TagIngestStats get stats => _stats;

  Future<void> ingestTags(Stream<Map<String, dynamic>> objects) async {
    var rows = <TableInfo, List<Insertable>>{};
    var buffered = 0;
    var processed = 0;

    void add(TableInfo table, Insertable row) => (rows[table] ??= []).add(row);

    Future<void> flush() async {
      if (buffered == 0) return;
      final r = rows;
      rows = {};
      buffered = 0;
      await db.batch((b) {
        for (final e in r.entries) {
          b.insertAll(e.key, e.value, mode: InsertMode.insertOrReplace);
        }
      });
    }

    await for (final json in objects) {
      if (json['object'] != 'tag') continue;
      final art = switch (json['type']) {
        'oracle' => false,
        'illustration' => true,
        _ => null,
      };
      final id = json['id'] as String?;
      final slug = json['slug'] as String?;
      if (art == null || id == null || slug == null) continue;

      final label = json['label'] as String? ?? slug;
      final description = Value(json['description'] as String?);
      if (art) {
        add(
          db.artTags,
          ArtTagsCompanion.insert(
            id: id,
            slug: normalizeTag(slug),
            label: label,
            description: description,
          ),
        );
        _stats.artTags++;
      } else {
        add(
          db.tags,
          TagsCompanion.insert(
            id: id,
            slug: normalizeTag(slug),
            label: label,
            description: description,
          ),
        );
        _stats.tags++;
      }

      for (final alias in (json['aliases'] as List? ?? const [])) {
        if (alias is! String || alias.isEmpty) continue;
        final a = normalizeTag(alias);
        art
            ? add(
                db.artTagAliases,
                ArtTagAliasesCompanion.insert(alias: a, tagId: id),
              )
            : add(
                db.tagAliases,
                TagAliasesCompanion.insert(alias: a, tagId: id),
              );
      }
      // parent_ids carry the whole hierarchy; child_ids are the same edges
      // seen from the other side.
      for (final parent in (json['parent_ids'] as List? ?? const [])) {
        if (parent is! String || parent.isEmpty) continue;
        art
            ? add(
                db.artTagEdges,
                ArtTagEdgesCompanion.insert(parentId: parent, childId: id),
              )
            : add(
                db.tagEdges,
                TagEdgesCompanion.insert(parentId: parent, childId: id),
              );
      }
      // Oracle taggings name a card; illustration taggings name an artwork.
      for (final tagging in (json['taggings'] as List? ?? const [])) {
        final t = tagging as Map<String, dynamic>;
        if (art) {
          final illustrationId = t['illustration_id'] as String?;
          if (illustrationId == null) continue;
          add(
            db.artTagIllustrations,
            ArtTagIllustrationsCompanion.insert(
              tagId: id,
              illustrationId: illustrationId,
            ),
          );
          _stats.artTaggings++;
        } else {
          final oracleId = t['oracle_id'] as String?;
          if (oracleId == null) continue;
          add(
            db.tagCards,
            TagCardsCompanion.insert(tagId: id, oracleId: oracleId),
          );
          _stats.taggings++;
        }
      }

      processed++;
      if (++buffered >= _batchSize) {
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
      TagPackMetaKeys.artTagCount: '${_stats.artTags}',
      TagPackMetaKeys.artTaggingCount: '${_stats.artTaggings}',
      if (bulkUpdatedAt != null) TagPackMetaKeys.bulkUpdatedAt: bulkUpdatedAt,
    };
    await db.batch(
      (b) => b.insertAll(db.tagPackMeta, [
        for (final e in entries.entries)
          TagPackMetaCompanion.insert(key: e.key, value: e.value),
      ], mode: InsertMode.insertOrReplace),
    );
  }
}
