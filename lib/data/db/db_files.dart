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

  /// Crash hygiene: remove leftovers from an interrupted sync/swap.
  void cleanupStray() {
    for (final f in [
      staging,
      old,
      File('${old.path}-wal'),
      File('${old.path}-shm'),
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
}
