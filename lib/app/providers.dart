import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart' show RangeValues;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/errors.dart';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/db/database.dart';
import '../data/db/db_files.dart';
import '../data/db/tables.dart';
import '../data/images/art_saver.dart';
import '../data/images/image_store.dart';
import '../data/repo/card_repository.dart';
import '../data/sync/bulk_api.dart';
import '../data/sync/downloader.dart';
import '../data/sync/sync_progress.dart';
import '../data/sync/sync_repository.dart';
import '../data/tags/tag_database.dart' show TagPackMetaKeys;
import '../data/tags/tag_ingest_isolate.dart';
import '../search/compiler/sql_compiler.dart';
import '../search/parser/grammar.dart';

/// Overridden in main() after platform directories resolve.
final dbFilesProvider = Provider<DbFiles>(
  (ref) => throw UnimplementedError('set in main()'),
);
final appVersionProvider = Provider<String>(
  (ref) => throw UnimplementedError('set in main()'),
);
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('set in main()'),
);

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Holds the live database handle; null until the first sync completes.
/// Swapping in a freshly ingested staging DB replaces the state, which
/// cascades a refresh through every data provider below.
class DatabaseManager extends Notifier<AppDatabase?> {
  @override
  AppDatabase? build() {
    final files = ref.watch(dbFilesProvider);
    final db = files.hasLiveDatabase
        ? AppDatabase.background(files.live, tagPack: files.tags)
        : null;
    ref.onDispose(() => db?.close());
    return db;
  }

  Future<void> swapInStaging() async {
    final files = ref.read(dbFilesProvider);
    final current = state;
    state = null;
    await current?.close();
    files.swapStagingIntoLive();
    state = AppDatabase.background(files.live, tagPack: files.tags);
    ref.read(hasCardDataProvider.notifier).set(true);
  }

  /// Closes the live DB, runs [whileClosed], and reopens. Used by the tag
  /// pack install/delete: the pack is attached per connection, so changing
  /// tags.db requires every connection to re-run its setup (and Windows
  /// won't rename/delete a file that is still open).
  Future<void> reopen({void Function()? whileClosed}) async {
    final files = ref.read(dbFilesProvider);
    final current = state;
    state = null;
    await current?.close();
    whileClosed?.call();
    if (files.hasLiveDatabase) {
      state = AppDatabase.background(files.live, tagPack: files.tags);
    }
  }

  /// Deletes the local card database, returning the app to onboarding. The
  /// image cache is left alone (harmless, and cheap to rebuild on demand).
  Future<void> purge() async {
    final files = ref.read(dbFilesProvider);
    final current = state;
    state = null;
    await current?.close();
    files.deleteAll();
    ref.read(hasCardDataProvider.notifier).set(false);
  }
}

final databaseProvider = NotifierProvider<DatabaseManager, AppDatabase?>(
  DatabaseManager.new,
);

/// Whether card data is installed, for the router's onboarding redirect.
/// Unlike [databaseProvider], it stays true while the DB is briefly closed
/// for an update swap or tag-pack change, so those don't bounce the user
/// through onboarding to the search page.
class HasCardDataNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(dbFilesProvider).hasLiveDatabase;

  void set(bool value) => state = value;
}

final hasCardDataProvider = NotifierProvider<HasCardDataNotifier, bool>(
  HasCardDataNotifier.new,
);

final cardRepositoryProvider = Provider<CardRepository?>((ref) {
  final db = ref.watch(databaseProvider);
  return db == null ? null : CardRepository(db);
});

final metaProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  return repo == null ? const {} : repo.metaEntries();
});

// ------------------------------------------------------------------ sync

class SyncController extends Notifier<SyncProgress?> {
  bool _running = false;

  @override
  SyncProgress? build() => null;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    try {
      final repo = SyncRepository(
        files: ref.read(dbFilesProvider),
        client: ref.read(httpClientProvider),
        appVersion: ref.read(appVersionProvider),
      );
      await for (final progress in repo.run()) {
        state = progress;
        if (progress is SyncDone) {
          state = const SyncSwapping();
          await ref.read(databaseProvider.notifier).swapInStaging();
          state = progress;
        }
      }
    } catch (e) {
      state = SyncFailed(e.toString());
    } finally {
      _running = false;
    }
  }

  void reset() => state = null;
}

final syncControllerProvider = NotifierProvider<SyncController, SyncProgress?>(
  SyncController.new,
);

// ---------------------------------------------------------- offline images

final imageStoreProvider = Provider<ImageStore>((ref) {
  final dbRoot = ref.watch(dbFilesProvider).root; // <support>/db
  return ImageStore(Directory(p.join(dbRoot.parent.path, 'images')));
});

class ImagePackProgress {
  final int total;
  final int done;
  final int failed;
  final bool running;

  const ImagePackProgress({
    required this.total,
    required this.done,
    required this.failed,
    required this.running,
  });
}

/// Downloads one 'normal' image per card into the [ImageStore]. Re-running
/// skips files that already exist, so cancel/failures resume naturally.
class ImagePackController extends Notifier<ImagePackProgress?> {
  bool _cancel = false;

  @override
  ImagePackProgress? build() => null;

  Future<void> start() async {
    if (state?.running == true) return;
    final repo = ref.read(cardRepositoryProvider);
    if (repo == null) return;
    final store = ref.read(imageStoreProvider);
    final client = ref.read(httpClientProvider);
    _cancel = false;

    final targets = await repo.imageTargets();
    store.root.createSync(recursive: true);
    final missing = [
      for (final t in targets)
        if (!store.fileFor(t.$1).existsSync()) t,
    ];
    var done = targets.length - missing.length;
    var failed = 0;
    void publish(bool running) {
      state = ImagePackProgress(
        total: targets.length,
        done: done,
        failed: failed,
        running: running,
      );
    }

    publish(true);

    // Small worker pool: parallel enough to be fast, polite to the CDN.
    // Single isolate, no await between read and increment — no race.
    var next = 0;
    Future<void> worker() async {
      while (!_cancel && next < missing.length) {
        final (oracleId, url) = missing[next++];
        final ok = await store.download(client, oracleId, url);
        ok ? done++ : failed++;
        if ((done + failed) % 25 == 0) publish(true);
      }
    }

    await Future.wait([for (var i = 0; i < 4; i++) worker()]);
    publish(false);
  }

  void cancel() => _cancel = true;

  Future<void> deleteAll() async {
    cancel();
    ref.read(imageStoreProvider).deleteAll();
    state = null;
  }
}

final imagePackProvider =
    NotifierProvider<ImagePackController, ImagePackProgress?>(
      ImagePackController.new,
    );

// ------------------------------------------------------------- art export

/// The folder "Download all art" saves into on Android, picked once and
/// remembered. Persisted in prefs (not the card DB, which gets replaced on
/// every update).
class ArtFolderNotifier extends Notifier<ArtFolder?> {
  static const _uriKey = 'artFolderUri';
  static const _nameKey = 'artFolderName';

  @override
  ArtFolder? build() {
    final prefs = ref.watch(prefsProvider);
    final uri = prefs.getString(_uriKey);
    final name = prefs.getString(_nameKey);
    return uri == null || name == null ? null : (uri: uri, name: name);
  }

  /// Opens the folder picker; keeps the current folder if the user cancels.
  Future<ArtFolder?> pick() async {
    final picked = await ArtFolderChannel.pickFolder(current: state);
    if (picked != null) {
      state = picked;
      final prefs = ref.read(prefsProvider);
      await prefs.setString(_uriKey, picked.uri);
      await prefs.setString(_nameKey, picked.name);
    }
    return picked;
  }

  void clear() {
    state = null;
    ref.read(prefsProvider)
      ..remove(_uriKey)
      ..remove(_nameKey);
  }
}

final artFolderProvider = NotifierProvider<ArtFolderNotifier, ArtFolder?>(
  ArtFolderNotifier.new,
);

class ArtExportProgress {
  final String oracleId;
  final ArtSaver saver;
  final int total;
  final int done;
  final int failed;
  final bool running;

  /// The save folder disappeared mid-run; the run stopped and the folder
  /// setting was cleared.
  final bool folderLost;

  const ArtExportProgress({
    required this.oracleId,
    required this.saver,
    required this.total,
    required this.done,
    required this.failed,
    required this.running,
    this.folderLost = false,
  });
}

/// Saves full-card PNGs of every printing of one card through an
/// [ArtSaver]. One export at a time; it keeps running if the user leaves the
/// detail screen.
class ArtExportController extends Notifier<ArtExportProgress?> {
  bool _cancel = false;

  @override
  ArtExportProgress? build() => null;

  Future<void> start(
    String oracleId,
    List<ArtTarget> targets,
    ArtSaver saver,
  ) async {
    if (state?.running == true) return;
    final client = ref.read(httpClientProvider);
    _cancel = false;

    var done = 0;
    var failed = 0;
    var folderLost = false;
    void publish(bool running) {
      state = ArtExportProgress(
        oracleId: oracleId,
        saver: saver,
        total: targets.length,
        done: done,
        failed: failed,
        running: running,
        folderLost: folderLost,
      );
    }

    publish(true);

    // Same pool shape as ImagePackController: polite to the CDN, and no
    // await between read and increment of `next`, so no race.
    var next = 0;
    Future<void> worker() async {
      while (!_cancel && next < targets.length) {
        final target = targets[next++];
        try {
          final response = await client.get(Uri.parse(target.url));
          if (response.statusCode != 200) throw Exception(response.statusCode);
          await saver.save(target.name, response.bodyBytes);
          done++;
        } on ArtFolderLostException {
          // Every later write would fail the same way.
          folderLost = true;
          _cancel = true;
        } catch (_) {
          failed++;
        }
        publish(true);
      }
    }

    await Future.wait([for (var i = 0; i < 4; i++) worker()]);
    if (folderLost) ref.read(artFolderProvider.notifier).clear();
    publish(false);
  }

  void cancel() => _cancel = true;
}

final artExportProvider =
    NotifierProvider<ArtExportController, ArtExportProgress?>(
      ArtExportController.new,
    );

/// (downloaded, total) for the data screen's idle status line.
final imagePackStatusProvider = FutureProvider<(int, int)>((ref) async {
  ref.watch(imagePackProvider); // refresh whenever a download run updates
  final repo = ref.watch(cardRepositoryProvider);
  final total = repo == null ? 0 : (await repo.imageTargets()).length;
  return (ref.watch(imageStoreProvider).countSync(), total);
});

// ------------------------------------------------------------- oracle tags

class TagPackProgress {
  final String label;

  /// 0..1 for the download phase; null = indeterminate.
  final double? fraction;
  final bool running;
  final String? error;

  const TagPackProgress({
    required this.label,
    this.fraction,
    required this.running,
    this.error,
  });
}

/// Downloads the `oracle_tags` and `art_tags` bulk files and installs them
/// together as tags.db via a staging swap. Only runs when the user taps it —
/// never automatically; a re-tap is the refresh path.
class TagPackController extends Notifier<TagPackProgress?> {
  /// Sanity floor: a truncated download or format break must never replace
  /// a good pack (the real files have thousands of tags and hundreds of
  /// thousands of taggings each).
  static const _minTags = 100;
  static const _minTaggings = 10000;

  @override
  TagPackProgress? build() => null;

  Future<void> start() async {
    if (state?.running == true) return;
    final files = ref.read(dbFilesProvider);
    final client = ref.read(httpClientProvider);
    final appVersion = ref.read(appVersionProvider);
    void publish(String label, {double? fraction}) => state = TagPackProgress(
      label: label,
      fraction: fraction,
      running: true,
    );

    final download = File(p.join(files.syncDir.path, 'oracle_tags.jsonl.gz'));
    final artDownload = File(p.join(files.syncDir.path, 'art_tags.jsonl.gz'));
    try {
      publish('Checking…');
      final api = BulkApi(client, appVersion: appVersion);
      final info = await api.fetchTagsInfo();

      files.syncDir.createSync(recursive: true);
      Future<void> fetch(BulkFileInfo file, File dest, String label) {
        var lastEmit = 0;
        return downloadFile(
          client,
          file.downloadUri,
          dest,
          headers: scryfallHeaders(appVersion),
          onProgress: (recv, total) {
            if (recv - lastEmit > 256 * 1024 || recv == total) {
              lastEmit = recv;
              publish(label, fraction: total == null ? null : recv / total);
            }
          },
        );
      }

      await fetch(info.oracle, download, 'Downloading oracle tags…');
      await fetch(info.art, artDownload, 'Downloading art tags…');

      publish('Importing tags…');
      final done =
          Completer<({int tags, int taggings, int artTags, int artTaggings})>();
      final port = ReceivePort();
      port.listen((msg) {
        final map = msg as Map;
        switch (map['type']) {
          case 'tags':
            publish('Importing tags… ${map['n']}');
          case 'done':
            done.complete((
              tags: map['tags'] as int,
              taggings: map['taggings'] as int,
              artTags: map['artTags'] as int,
              artTaggings: map['artTaggings'] as int,
            ));
          case 'error':
            done.completeError(StateError(map['message'] as String));
        }
      });
      try {
        await Isolate.spawn(
          tagIngestIsolateMain,
          TagIngestRequest(
            progressPort: port.sendPort,
            stagingDbPath: files.tagsStaging.path,
            tagsPath: download.path,
            tagsGzip: info.oracle.isGzip,
            artTagsPath: artDownload.path,
            artTagsGzip: info.art.isGzip,
            bulkUpdatedAt: info.oracle.updatedAt,
          ),
          errorsAreFatal: true,
        );
        final stats = await done.future;
        if (stats.tags < _minTags || stats.taggings < _minTaggings) {
          throw StateError(
            'ingest produced only ${stats.tags} tags — '
            'refusing to install',
          );
        }
        if (stats.artTags < _minTags || stats.artTaggings < _minTaggings) {
          throw StateError(
            'ingest produced only ${stats.artTags} art tags — '
            'refusing to install',
          );
        }
      } finally {
        port.close();
      }

      publish('Installing…');
      await ref
          .read(databaseProvider.notifier)
          .reopen(whileClosed: files.swapTagsStagingIntoLive);
      state = null; // idle — tagPackStatusProvider shows the installed pack
    } catch (e) {
      if (files.tagsStaging.existsSync()) files.tagsStaging.deleteSync();
      state = TagPackProgress(label: '', running: false, error: e.toString());
    } finally {
      for (final f in [download, artDownload]) {
        if (f.existsSync()) f.deleteSync();
      }
      ref.invalidate(tagPackStatusProvider);
    }
  }

  Future<void> delete() async {
    if (state?.running == true) return;
    final files = ref.read(dbFilesProvider);
    await ref
        .read(databaseProvider.notifier)
        .reopen(whileClosed: files.deleteTagData);
    state = null;
    ref.invalidate(tagPackStatusProvider);
  }
}

final tagPackProvider = NotifierProvider<TagPackController, TagPackProgress?>(
  TagPackController.new,
);

typedef TagPackStatus = ({
  int tags,
  int taggings,

  /// Null for a pack installed before art tags existed (no art tables).
  int? artTags,
  String? fetchedAt,
});

/// Installed-pack summary for the data screen; null = not installed.
final tagPackStatusProvider = FutureProvider<TagPackStatus?>((ref) async {
  final db = ref.watch(databaseProvider);
  final files = ref.watch(dbFilesProvider);
  if (db == null || !files.tags.existsSync()) return null;
  final meta = await db.tagPackMetaEntries();
  return (
    tags: int.tryParse(meta[TagPackMetaKeys.tagCount] ?? '') ?? 0,
    taggings: int.tryParse(meta[TagPackMetaKeys.taggingCount] ?? '') ?? 0,
    artTags: int.tryParse(meta[TagPackMetaKeys.artTagCount] ?? ''),
    fetchedAt: meta[TagPackMetaKeys.fetchedAt],
  );
});

/// Whether `atag:` can run: the installed tag pack has art tags. Older
/// oracle-only packs lack the art tables entirely.
final artTagsInstalledProvider = FutureProvider<bool>(
  (ref) async =>
      (await ref.watch(tagPackStatusProvider.future))?.artTags != null,
);

/// Whether the card database records illustrations per print (schema v2+).
/// Databases built before that need a card-data update for `atag:`.
final artIndexedProvider = FutureProvider<bool>((ref) async {
  final meta = await ref.watch(metaProvider.future);
  return (int.tryParse(meta[MetaKeys.schemaVersion] ?? '') ?? 0) >= 2;
});

/// Prefs keys for the update check. The /sets card total is the update
/// fingerprint: unlike the bulk file's updated_at (which changes every 12h
/// from price churn the app strips anyway), it only moves when cards are
/// actually added upstream.
class UpdatePrefs {
  static const checkAt = 'updateCheckAt';
  static const checkTotal = 'updateCheckTotal';
  static const dismissedTotal = 'updateDismissedTotal';
}

/// Current upstream /sets card total; null if offline with nothing cached.
/// Unless [force], a fetch newer than 24h is reused from prefs. Every
/// successful fetch refreshes the prefs cache.
Future<int?> _currentSetsTotal(Ref ref, {required bool force}) async {
  final prefs = ref.read(prefsProvider);
  final cached = prefs.getInt(UpdatePrefs.checkTotal);
  if (!force && cached != null) {
    final last = DateTime.tryParse(prefs.getString(UpdatePrefs.checkAt) ?? '');
    if (last != null &&
        DateTime.now().toUtc().difference(last.toUtc()).inHours < 24) {
      return cached;
    }
  }
  final api = BulkApi(
    ref.read(httpClientProvider),
    appVersion: ref.read(appVersionProvider),
  );
  try {
    final total = await api.fetchSetsCardTotal();
    await prefs.setInt(UpdatePrefs.checkTotal, total);
    await prefs.setString(
      UpdatePrefs.checkAt,
      DateTime.now().toUtc().toIso8601String(),
    );
    return total;
  } catch (_) {
    return cached; // offline — stale cache beats flip-flopping UI
  }
}

/// Whether new cards exist upstream. null = unknown (offline / no DB yet).
/// A database from before this check existed has no stored total; seed it
/// from the current one and report "up to date" — no spurious re-download
/// prompt, and the next real set release still triggers.
Future<bool?> _setsUpdateAvailable(Ref ref, {required bool force}) async {
  final meta = await ref.watch(metaProvider.future);
  final current = await _currentSetsTotal(ref, force: force);
  if (current == null) return null;
  final stored = int.tryParse(meta[MetaKeys.setsCardTotal] ?? '');
  if (stored == null) {
    final repo = ref.read(cardRepositoryProvider);
    if (repo == null) return null;
    await repo.setMetaEntry(MetaKeys.setsCardTotal, '$current');
    ref.invalidate(metaProvider);
    return false;
  }
  return current != stored;
}

/// Definitive server check for the data screen: true = new cards exist
/// upstream, false = up to date, null = couldn't reach Scryfall. No
/// throttle — one tiny GET per screen visit, refreshed after each sync
/// (the DB swap cascades through metaProvider).
final updateCheckProvider = FutureProvider.autoDispose<bool?>((ref) async {
  final meta = await ref.watch(metaProvider.future);
  if (meta.isEmpty) return true; // no database yet
  // Built by an older app: a re-download fills in what the new schema adds
  // (e.g. print_art for art tags).
  final built = int.tryParse(meta[MetaKeys.schemaVersion] ?? '') ?? 0;
  if (built < schemaVersionValue) return true;
  return _setsUpdateAvailable(ref, force: true);
});

/// The /sets total the user dismissed the banner at; the banner stays
/// hidden until the upstream total moves again.
class DismissedUpdateNotifier extends Notifier<int?> {
  @override
  int? build() => ref.watch(prefsProvider).getInt(UpdatePrefs.dismissedTotal);

  void dismiss(int total) {
    state = total;
    ref.read(prefsProvider).setInt(UpdatePrefs.dismissedTotal, total);
  }
}

final dismissedUpdateProvider = NotifierProvider<DismissedUpdateNotifier, int?>(
  DismissedUpdateNotifier.new,
);

/// Drives the search-screen banner: new cards exist upstream and the user
/// hasn't dismissed this particular total. Network-checked at most once
/// per 24h; dismissal recomputes instantly from the cached total.
final updateAvailableProvider = FutureProvider<bool>((ref) async {
  final dismissed = ref.watch(dismissedUpdateProvider);
  final available = await _setsUpdateAvailable(ref, force: false);
  if (available != true) return false;
  final current = ref.read(prefsProvider).getInt(UpdatePrefs.checkTotal);
  return current != null && current != dismissed;
});

// ---------------------------------------------------------------- search

const searchPageSize = 60;

class SearchState {
  final String query;
  final List<CardSummary> items;

  /// Match count. Null while the (slower) COUNT(*) is still running — results
  /// are already on screen by then.
  final int? total;

  /// First page of a new query is in flight (whole-grid spinner). Starts
  /// true so app launch shows a spinner, not a "no matches" flash.
  final bool loading;
  final bool loadingMore;
  final bool reachedEnd;
  final QueryError? error;

  const SearchState({
    this.query = '',
    this.items = const [],
    this.total,
    this.loading = true,
    this.loadingMore = false,
    this.reachedEnd = false,
    this.error,
  });

  bool get hasMore => !reachedEnd && error == null;

  SearchState copyWith({
    String? query,
    List<CardSummary>? items,
    int? total,
    bool? loading,
    bool? loadingMore,
    bool? reachedEnd,
    QueryError? error,
    bool clearError = false,
    bool clearTotal = false,
  }) => SearchState(
    query: query ?? this.query,
    items: items ?? this.items,
    total: clearTotal ? null : (total ?? this.total),
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    reachedEnd: reachedEnd ?? this.reachedEnd,
    error: clearError ? null : (error ?? this.error),
  );
}

class SearchNotifier extends Notifier<SearchState> {
  int _generation = 0;

  @override
  SearchState build() {
    // Reset on DB swap. The first query comes from the user's default filter
    // (settings); with no default that's an empty all-cards browse.
    if (ref.watch(cardRepositoryProvider) != null) {
      final initial = ref.read(filterProvider).toSyntax();
      Future.microtask(() => setQuery(initial));
    }
    return const SearchState();
  }

  /// An empty query means "browse everything" — compiled by hand since the
  /// parser has no empty production.
  Future<CompiledQuery> _compile(String query) async {
    if (query.trim().isEmpty) {
      return const CompiledQuery('1=1', [], 'cards.name COLLATE NOCASE ASC');
    }
    final root = ScryfallQueryParser.parse(query);
    // Both flags only gate atag:'s directions errors; an unreadable pack or
    // meta table reads as "not available".
    Future<bool> flag(FutureProvider<bool> p) =>
        ref.read(p.future).catchError((_) => false);
    return SqlCompiler.compile(
      root,
      tagsInstalled: ref.read(dbFilesProvider).tags.existsSync(),
      artTagsInstalled: await flag(artTagsInstalledProvider),
      artIndexed: await flag(artIndexedProvider),
    );
  }

  Future<void> setQuery(String query) async {
    final gen = ++_generation;
    final repo = ref.read(cardRepositoryProvider);
    if (repo == null) return;

    final CompiledQuery compiled;
    try {
      compiled = await _compile(query);
    } on QueryError catch (e) {
      if (gen != _generation) return;
      // Mid-typing errors (a half-typed field or unbalanced paren) shouldn't
      // wipe the visible results — keep them and just surface the message.
      state = state.copyWith(query: query, error: e, loading: false);
      return;
    }
    if (gen != _generation) return;

    state = state.copyWith(query: query, loading: true, clearError: true);

    // Paint the first page as soon as it's ready — do NOT wait on the count.
    final rows = await repo.searchRows(
      compiled,
      limit: searchPageSize,
      offset: 0,
    );
    if (gen != _generation) return; // superseded by a newer keystroke
    state = SearchState(
      query: query,
      items: rows,
      total: null,
      loading: false,
      reachedEnd: rows.length < searchPageSize,
    );

    // The count is the slow part; wait out rapid typing so superseded
    // queries never reach the database, then fold the number in.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (gen != _generation) return;
    final total = await repo.count(compiled);
    if (gen != _generation) return;
    state = state.copyWith(total: total);
  }

  Future<void> loadMore() async {
    final s = state;
    if (s.loadingMore || !s.hasMore) return;
    final repo = ref.read(cardRepositoryProvider);
    if (repo == null) return;
    final gen = _generation;
    state = s.copyWith(loadingMore: true);
    try {
      final compiled = await _compile(s.query);
      final rows = await repo.searchRows(
        compiled,
        limit: searchPageSize,
        offset: s.items.length,
      );
      if (gen != _generation) return;
      state = state.copyWith(
        items: [...s.items, ...rows],
        loadingMore: false,
        reachedEnd: rows.length < searchPageSize,
      );
    } on QueryError {
      if (gen != _generation) return;
      state = state.copyWith(loadingMore: false, reachedEnd: true);
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

// ---------------------------------------------------------------- filters

/// Structured filter selections. Persisted across sheet open/close so the
/// filter tab always reflects what's currently applied. The generated
/// [toSyntax] becomes the search query when the user hits Apply.
class FilterState {
  final String nameText;
  final Set<String> types;
  final String oracleText;

  /// Selected oracle tags as slug → label. The slug is what `otag:` needs;
  /// the label rides along so chips stay readable even if the tag pack is
  /// deleted out from under a saved filter.
  final Map<String, String> otags;

  /// Selected art tags, slug → label, same as [otags] but for `atag:`.
  final Map<String, String> atags;
  final Set<String> colors;
  final String colorMode; // ':', '=', '<='
  final Set<String> identity;
  final RangeValues mv;

  /// Power and toughness ranges; [statMax] as the upper end means "no
  /// limit" (a handful of cards go past it).
  final RangeValues pow;
  final RangeValues tou;
  final String? format;
  final Set<String> rarities;
  final String? setCode;
  final String? setLabel;
  final String sort; // name, cmc, released, set, edhrec, rarity, power
  final bool sortAscending;

  const FilterState({
    this.nameText = '',
    this.types = const {},
    this.oracleText = '',
    this.otags = const {},
    this.atags = const {},
    this.colors = const {},
    this.colorMode = ':',
    this.identity = const {},
    this.mv = const RangeValues(0, mvMax),
    this.pow = const RangeValues(0, statMax),
    this.tou = const RangeValues(0, statMax),
    this.format,
    this.rarities = const {},
    this.setCode,
    this.setLabel,
    this.sort = 'name',
    this.sortAscending = true,
  });

  /// Slider upper bounds; the top stop means "no limit".
  static const double mvMax = 16;
  static const double statMax = 10;

  FilterState copyWith({
    String? nameText,
    Set<String>? types,
    String? oracleText,
    Map<String, String>? otags,
    Map<String, String>? atags,
    Set<String>? colors,
    String? colorMode,
    Set<String>? identity,
    RangeValues? mv,
    RangeValues? pow,
    RangeValues? tou,
    String? format,
    bool clearFormat = false,
    Set<String>? rarities,
    String? setCode,
    String? setLabel,
    bool clearSet = false,
    String? sort,
    bool? sortAscending,
  }) => FilterState(
    nameText: nameText ?? this.nameText,
    types: types ?? this.types,
    oracleText: oracleText ?? this.oracleText,
    otags: otags ?? this.otags,
    atags: atags ?? this.atags,
    colors: colors ?? this.colors,
    colorMode: colorMode ?? this.colorMode,
    identity: identity ?? this.identity,
    mv: mv ?? this.mv,
    pow: pow ?? this.pow,
    tou: tou ?? this.tou,
    format: clearFormat ? null : (format ?? this.format),
    rarities: rarities ?? this.rarities,
    setCode: clearSet ? null : (setCode ?? this.setCode),
    setLabel: clearSet ? null : (setLabel ?? this.setLabel),
    sort: sort ?? this.sort,
    sortAscending: sortAscending ?? this.sortAscending,
  );

  String toSyntax() {
    final parts = <String>[];
    String quote(String v) => v.contains(' ') ? '"$v"' : v;

    // Text fields mirror Scryfall's advanced-search form: each word is its
    // own ANDed term; "quoted spans" stay together as phrases.
    for (final term in _terms(nameText)) {
      parts.add('name:${quote(term)}');
    }
    for (final t in types) {
      parts.add('t:${quote(t.toLowerCase())}');
    }
    for (final term in _terms(oracleText)) {
      parts.add('o:${quote(term)}');
    }
    for (final slug in otags.keys) {
      parts.add('otag:${quote(slug)}');
    }
    for (final slug in atags.keys) {
      parts.add('atag:${quote(slug)}');
    }
    if (colors.isNotEmpty) {
      parts.add('c$colorMode${colors.join().toLowerCase()}');
    }
    if (identity.isNotEmpty) parts.add('id:${identity.join().toLowerCase()}');
    void range(String field, RangeValues r, double max) {
      if (r.start > 0) parts.add('$field>=${r.start.round()}');
      if (r.end < max) parts.add('$field<=${r.end.round()}');
    }

    range('mv', mv, mvMax);
    range('pow', pow, statMax);
    range('tou', tou, statMax);
    if (format != null) parts.add('f:$format');
    if (rarities.isNotEmpty) {
      parts.add(
        rarities.length == 1
            ? 'r:${rarities.first}'
            : '(${rarities.map((r) => 'r:$r').join(' or ')})',
      );
    }
    if (setCode != null) parts.add('s:$setCode');
    if (sort != 'name' || !sortAscending) {
      parts
        ..add('order:$sort')
        ..add('direction:${sortAscending ? 'asc' : 'desc'}');
    }
    return parts.join(' ');
  }

  /// Whitespace-separated terms, keeping "double-quoted spans" together.
  /// Stray quotes in unquoted words are dropped so a half-typed quote can't
  /// produce unparseable syntax.
  static List<String> _terms(String text) => [
    for (final m in RegExp(r'"([^"]*)"|(\S+)').allMatches(text))
      if (((m.group(1) ?? m.group(2))!).replaceAll('"', '').trim() case final t
          when t.isNotEmpty)
        t,
  ];

  Map<String, dynamic> toJson() => {
    'nameText': nameText,
    'types': types.toList(),
    'oracleText': oracleText,
    'otags': otags,
    'atags': atags,
    'colors': colors.toList(),
    'colorMode': colorMode,
    'identity': identity.toList(),
    'mvStart': mv.start,
    'mvEnd': mv.end,
    'powStart': pow.start,
    'powEnd': pow.end,
    'touStart': tou.start,
    'touEnd': tou.end,
    'format': format,
    'rarities': rarities.toList(),
    'setCode': setCode,
    'setLabel': setLabel,
    'sort': sort,
    'sortAscending': sortAscending,
  };

  static FilterState fromJson(Map<String, dynamic> json) => FilterState(
    nameText: json['nameText'] as String? ?? '',
    types: {...(json['types'] as List? ?? const []).cast<String>()},
    oracleText: json['oracleText'] as String? ?? '',
    otags: {...(json['otags'] as Map? ?? const {}).cast<String, String>()},
    atags: {...(json['atags'] as Map? ?? const {}).cast<String, String>()},
    colors: {...(json['colors'] as List? ?? const []).cast<String>()},
    colorMode: json['colorMode'] as String? ?? ':',
    identity: {...(json['identity'] as List? ?? const []).cast<String>()},
    mv: _range(json, 'mv', mvMax),
    pow: _range(json, 'pow', statMax),
    tou: _range(json, 'tou', statMax),
    format: json['format'] as String?,
    rarities: {...(json['rarities'] as List? ?? const []).cast<String>()},
    setCode: json['setCode'] as String?,
    setLabel: json['setLabel'] as String?,
    sort: json['sort'] as String? ?? 'name',
    sortAscending: json['sortAscending'] as bool? ?? true,
  );

  /// Missing keys (filters saved before that slider existed) mean the full
  /// range.
  static RangeValues _range(
    Map<String, dynamic> json,
    String key,
    double max,
  ) => RangeValues(
    (json['${key}Start'] as num? ?? 0).toDouble(),
    (json['${key}End'] as num? ?? max).toDouble(),
  );

  /// This filter with [section] back at its default — what switching the
  /// section off in settings does, so a hidden filter never applies.
  FilterState cleared(FilterSection section) {
    const d = FilterState();
    return switch (section) {
      FilterSection.name => copyWith(nameText: ''),
      FilterSection.types => copyWith(types: const {}),
      FilterSection.rulesText => copyWith(oracleText: ''),
      FilterSection.oracleTags => copyWith(otags: const {}),
      FilterSection.artTags => copyWith(atags: const {}),
      FilterSection.colors => copyWith(
        colors: const {},
        colorMode: d.colorMode,
      ),
      FilterSection.identity => copyWith(identity: const {}),
      FilterSection.manaValue => copyWith(mv: d.mv),
      FilterSection.power => copyWith(pow: d.pow),
      FilterSection.toughness => copyWith(tou: d.tou),
      FilterSection.format => copyWith(clearFormat: true),
      FilterSection.rarity => copyWith(rarities: const {}),
      FilterSection.set => copyWith(clearSet: true),
      FilterSection.sort => copyWith(
        sort: d.sort,
        sortAscending: d.sortAscending,
      ),
    };
  }

  /// Whether [section] holds anything other than its default.
  bool isActive(FilterSection section) {
    const d = FilterState();
    return switch (section) {
      FilterSection.name => nameText.trim().isNotEmpty,
      FilterSection.types => types.isNotEmpty,
      FilterSection.rulesText => oracleText.trim().isNotEmpty,
      FilterSection.oracleTags => otags.isNotEmpty,
      FilterSection.artTags => atags.isNotEmpty,
      FilterSection.colors => colors.isNotEmpty,
      FilterSection.identity => identity.isNotEmpty,
      FilterSection.manaValue => mv != d.mv,
      FilterSection.power => pow != d.pow,
      FilterSection.toughness => tou != d.tou,
      FilterSection.format => format != null,
      FilterSection.rarity => rarities.isNotEmpty,
      FilterSection.set => setCode != null,
      FilterSection.sort => sort != d.sort || sortAscending != d.sortAscending,
    };
  }
}

/// The filter panel's sections, in display order, for the settings toggles
/// that hide the ones a user never touches.
enum FilterSection {
  name('Card name'),
  types('Types'),
  rulesText('Rules text'),
  oracleTags('Oracle tags'),
  artTags('Art tags'),
  colors('Colors'),
  identity('Commander identity'),
  manaValue('Mana value'),
  power('Power'),
  toughness('Toughness'),
  format('Format'),
  rarity('Rarity'),
  set('Set'),
  sort('Sort');

  final String label;
  const FilterSection(this.label);
}

/// Filter-panel sections the user switched off in settings. Persisted by
/// enum name; unknown names (from another app version) are dropped.
class HiddenFilterSectionsNotifier extends Notifier<Set<FilterSection>> {
  static const _key = 'hiddenFilterSections';

  static const defaultHidden = {
    FilterSection.oracleTags,
    FilterSection.artTags,
    FilterSection.manaValue,
    FilterSection.power,
    FilterSection.toughness,
    FilterSection.format,
    FilterSection.rarity,
    FilterSection.set,
  };

  @override
  Set<FilterSection> build() {
    final names = ref.watch(prefsProvider).getStringList(_key);
    if (names == null) return defaultHidden;
    return {
      for (final s in FilterSection.values)
        if (names.contains(s.name)) s,
    };
  }

  void setVisible(FilterSection section, bool visible) {
    final next = {...state};
    visible ? next.remove(section) : next.add(section);
    state = next;
    ref.read(prefsProvider).setStringList(_key, [for (final s in next) s.name]);
  }
}

final hiddenFilterSectionsProvider =
    NotifierProvider<HiddenFilterSectionsNotifier, Set<FilterSection>>(
      HiddenFilterSectionsNotifier.new,
    );

/// The filter applied on app start and by Reset, edited from the settings
/// screen and persisted across launches.
class DefaultFilterNotifier extends Notifier<FilterState> {
  static const _key = 'defaultFilter';

  @override
  FilterState build() {
    final raw = ref.watch(prefsProvider).getString(_key);
    if (raw == null) return const FilterState();
    try {
      return FilterState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const FilterState(); // corrupt/stale — fall back to no filter
    }
  }

  void set(FilterState next) {
    state = next;
    ref.read(prefsProvider).setString(_key, jsonEncode(next.toJson()));
  }
}

final defaultFilterProvider =
    NotifierProvider<DefaultFilterNotifier, FilterState>(
      DefaultFilterNotifier.new,
    );

class FilterNotifier extends Notifier<FilterState> {
  // Watching means a settings edit immediately becomes the active filter.
  @override
  FilterState build() => ref.watch(defaultFilterProvider);

  void set(FilterState next) => state = next;
  void reset() => state = ref.read(defaultFilterProvider);
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
);

// ---------------------------------------------------------- cards per row

const cardColumnOptions = [1, 2, 3, 4];

/// What the grids showed before this was configurable, on a phone.
const defaultCardColumns = 2;

/// How many card tiles the result grids fit across. A count rather than a
/// width, so what the user picks is what they get on every screen size.
/// Persisted in prefs (not the card DB, which gets replaced on every update).
class CardColumnsNotifier extends Notifier<int> {
  static const _key = 'cardColumns';

  @override
  int build() {
    final raw = ref.watch(prefsProvider).getInt(_key);
    // Guard the range so a stale or hand-edited value can't lay out a grid
    // with zero or absurdly many columns.
    return cardColumnOptions.contains(raw) ? raw! : defaultCardColumns;
  }

  void set(int next) {
    state = next;
    ref.read(prefsProvider).setInt(_key, next);
  }
}

final cardColumnsProvider = NotifierProvider<CardColumnsNotifier, int>(
  CardColumnsNotifier.new,
);

// ----------------------------------------------------------- saved cards

/// Oracle ids the user bookmarked to view later, newest first. Persisted in
/// prefs (not the card DB, which gets replaced on every data update).
class SavedCardsNotifier extends Notifier<List<String>> {
  static const _key = 'savedCards';

  @override
  List<String> build() =>
      ref.watch(prefsProvider).getStringList(_key) ?? const [];

  bool isSaved(String oracleId) => state.contains(oracleId);

  void toggle(String oracleId) =>
      isSaved(oracleId) ? remove(oracleId) : _set([oracleId, ...state]);

  void remove(String oracleId) => _set([
    for (final id in state)
      if (id != oracleId) id,
  ]);

  void clear() => _set(const []);

  void _set(List<String> next) {
    state = next;
    ref.read(prefsProvider).setStringList(_key, next);
  }
}

final savedCardsProvider = NotifierProvider<SavedCardsNotifier, List<String>>(
  SavedCardsNotifier.new,
);

final savedCardSummariesProvider = FutureProvider<List<CardSummary>>((
  ref,
) async {
  final ids = ref.watch(savedCardsProvider);
  final repo = ref.watch(cardRepositoryProvider);
  if (repo == null || ids.isEmpty) return const [];
  return repo.summariesByIds(ids);
});

// ---------------------------------------------------------------- detail

final cardDetailProvider = FutureProvider.autoDispose
    .family<CardDetail?, ({String oracleId, String? printId})>((ref, args) {
      final repo = ref.watch(cardRepositoryProvider);
      if (repo == null) return Future.value(null);
      return repo.detail(args.oracleId, printId: args.printId);
    });

final allSetsProvider = FutureProvider<List<(String, String)>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  return repo == null ? const [] : repo.allSets();
});

final allTypesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  return repo == null ? const [] : repo.allTypes();
});

/// Oracle tags on one card, or empty when the pack isn't installed — the
/// detail screen reads "empty" as "nothing to show" and omits the section.
final cardTagsProvider = FutureProvider.autoDispose
    .family<List<(String, String)>, String>((ref, oracleId) async {
      final repo = ref.watch(cardRepositoryProvider);
      if (repo == null || !ref.watch(dbFilesProvider).tags.existsSync()) {
        return const [];
      }
      return repo.tagsForCard(oracleId);
    });

/// Art tags on one printing, or empty without an art-tag pack or card data
/// that records illustrations — the detail screen then omits the section.
final cardArtTagsProvider = FutureProvider.autoDispose
    .family<List<(String, String)>, String>((ref, printId) async {
      final repo = ref.watch(cardRepositoryProvider);
      if (repo == null ||
          !await ref.watch(artTagsInstalledProvider.future) ||
          !await ref.watch(artIndexedProvider.future)) {
        return const [];
      }
      return repo.artTagsForPrint(printId);
    });

/// Art tags for the filter sheet, or empty when the pack has none (not
/// installed, or from before art tags) — which hides the section.
final allArtTagsProvider = FutureProvider<List<(String, String)>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  if (repo == null || !await ref.watch(artTagsInstalledProvider.future)) {
    return const [];
  }
  return repo.allArtTags();
});

/// Oracle tags for the filter sheet, or empty when the pack isn't installed —
/// the UI reads "empty" as "no pack" and hides the section. Installing or
/// deleting the pack reopens the database, which rebuilds the repository and
/// re-runs this, so no separate reactive install flag is needed.
final allTagsProvider = FutureProvider<List<(String, String)>>((ref) async {
  final repo = ref.watch(cardRepositoryProvider);
  if (repo == null || !ref.watch(dbFilesProvider).tags.existsSync()) {
    return const [];
  }
  return repo.allTags();
});
