import 'dart:io';

import 'package:path/path.dart' as p;

/// Locations of the live/staging database files and the atomic swap between
/// them. The staging DB is built by the ingest isolate; only the rename
/// moment touches the live handle.
class DbFiles {
  final Directory root; // <application support>/db

  DbFiles(this.root);

  File get live => File(p.join(root.path, 'scryfall.db'));
  File get staging => File(p.join(root.path, 'scryfall_staging.db'));
  File get old => File(p.join(root.path, 'scryfall_old.db'));
  Directory get syncDir => Directory(p.join(root.path, 'sync'));

  /// Optional oracle-tag pack, attached to the live DB when present. Its
  /// existence is the install sentinel: the file is only ever created by a
  /// successful staging swap, so `tags.existsSync()` ⟺ pack installed.
  File get tags => File(p.join(root.path, 'tags.db'));
  File get tagsStaging => File(p.join(root.path, 'tags_staging.db'));

  /// Crash hygiene: remove leftovers from an interrupted sync/swap.
  void cleanupStray() {
    for (final f in [
      staging,
      old,
      File('${old.path}-wal'),
      File('${old.path}-shm'),
      tagsStaging,
      File('${tagsStaging.path}-wal'),
      File('${tagsStaging.path}-shm'),
    ]) {
      if (f.existsSync()) f.deleteSync();
    }
  }

  /// Called with the live database CLOSED. Renames live -> old,
  /// staging -> live, then removes the old files.
  void swapStagingIntoLive() {
    if (!staging.existsSync()) {
      throw StateError('no staging database to swap in');
    }
    for (final suffix in ['-wal', '-shm']) {
      final side = File('${live.path}$suffix');
      if (side.existsSync()) side.deleteSync();
    }
    if (live.existsSync()) live.renameSync(old.path);
    staging.renameSync(live.path);
    if (old.existsSync()) old.deleteSync();
  }

  bool get hasLiveDatabase => live.existsSync();

  /// Called with the live database CLOSED (the tag pack is attached to its
  /// connections). Replaces any installed tag pack with the staged one.
  void swapTagsStagingIntoLive() {
    if (!tagsStaging.existsSync()) {
      throw StateError('no staging tag database to swap in');
    }
    deleteTagData();
    tagsStaging.renameSync(tags.path);
  }

  /// Called with the live database CLOSED. Removes the installed tag pack.
  void deleteTagData() {
    for (final f in [
      tags,
      File('${tags.path}-wal'),
      File('${tags.path}-shm'),
    ]) {
      if (f.existsSync()) f.deleteSync();
    }
  }

  /// Called with the live database CLOSED. Removes the live DB and all
  /// sync/staging artifacts, returning the app to a fresh state. The tag
  /// pack is left alone (like the image store): it is oracle_id-keyed, so
  /// it stays valid across card re-downloads.
  void deleteAll() {
    cleanupStray();
    for (final f in [live, File('${live.path}-wal'), File('${live.path}-shm')]) {
      if (f.existsSync()) f.deleteSync();
    }
    if (syncDir.existsSync()) syncDir.deleteSync(recursive: true);
  }
}
