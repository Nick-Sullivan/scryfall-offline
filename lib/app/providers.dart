import 'dart:async';
import 'dart:convert';

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
import '../data/images/image_store.dart';
import '../data/repo/card_repository.dart';
import '../data/sync/bulk_api.dart';
import '../data/sync/sync_progress.dart';
import '../data/sync/sync_repository.dart';
import '../search/compiler/sql_compiler.dart';
import '../search/parser/grammar.dart';

/// Overridden in main() after platform directories resolve.
final dbFilesProvider =
    Provider<DbFiles>((ref) => throw UnimplementedError('set in main()'));
final appVersionProvider =
    Provider<String>((ref) => throw UnimplementedError('set in main()'));
final prefsProvider = Provider<SharedPreferences>(
    (ref) => throw UnimplementedError('set in main()'));

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
    final db = files.hasLiveDatabase ? AppDatabase.background(files.live) : null;
    ref.onDispose(() => db?.close());
    return db;
  }

  Future<void> swapInStaging() async {
    final files = ref.read(dbFilesProvider);
    final current = state;
    state = null;
    await current?.close();
    files.swapStagingIntoLive();
    state = AppDatabase.background(files.live);
  }

  /// Deletes the local card database, returning the app to onboarding. The
  /// image cache is left alone (harmless, and cheap to rebuild on demand).
  Future<void> purge() async {
    final files = ref.read(dbFilesProvider);
    final current = state;
    state = null;
    await current?.close();
    files.deleteAll();
  }
}

final databaseProvider =
    NotifierProvider<DatabaseManager, AppDatabase?>(DatabaseManager.new);

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

final syncControllerProvider =
    NotifierProvider<SyncController, SyncProgress?>(SyncController.new);

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
        if (!store.fileFor(t.$1).existsSync()) t
    ];
    var done = targets.length - missing.length;
    var failed = 0;
    void publish(bool running) {
      state = ImagePackProgress(
          total: targets.length, done: done, failed: failed, running: running);
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
        ImagePackController.new);

/// (downloaded, total) for the data screen's idle status line.
final imagePackStatusProvider = FutureProvider<(int, int)>((ref) async {
  ref.watch(imagePackProvider); // refresh whenever a download run updates
  final repo = ref.watch(cardRepositoryProvider);
  final total = repo == null ? 0 : (await repo.imageTargets()).length;
  return (ref.watch(imageStoreProvider).countSync(), total);
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
  final api = BulkApi(ref.read(httpClientProvider),
      appVersion: ref.read(appVersionProvider));
  try {
    final total = await api.fetchSetsCardTotal();
    await prefs.setInt(UpdatePrefs.checkTotal, total);
    await prefs.setString(
        UpdatePrefs.checkAt, DateTime.now().toUtc().toIso8601String());
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

final dismissedUpdateProvider =
    NotifierProvider<DismissedUpdateNotifier, int?>(DismissedUpdateNotifier.new);

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
  }) =>
      SearchState(
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
  static CompiledQuery _compile(String query) => query.trim().isEmpty
      ? const CompiledQuery('1=1', [], 'cards.name COLLATE NOCASE ASC')
      : SqlCompiler.compile(ScryfallQueryParser.parse(query));

  Future<void> setQuery(String query) async {
    final gen = ++_generation;
    final repo = ref.read(cardRepositoryProvider);
    if (repo == null) return;

    final CompiledQuery compiled;
    try {
      compiled = _compile(query);
    } on QueryError catch (e) {
      // Mid-typing errors (a half-typed field or unbalanced paren) shouldn't
      // wipe the visible results — keep them and just surface the message.
      state = state.copyWith(query: query, error: e, loading: false);
      return;
    }

    state = state.copyWith(query: query, loading: true, clearError: true);

    // Paint the first page as soon as it's ready — do NOT wait on the count.
    final rows =
        await repo.searchRows(compiled, limit: searchPageSize, offset: 0);
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
      final compiled = _compile(s.query);
      final rows = await repo.searchRows(compiled,
          limit: searchPageSize, offset: s.items.length);
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

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

// ---------------------------------------------------------------- filters

/// Structured filter selections. Persisted across sheet open/close so the
/// filter tab always reflects what's currently applied. The generated
/// [toSyntax] becomes the search query when the user hits Apply.
class FilterState {
  final String nameText;
  final Set<String> types;
  final String oracleText;
  final Set<String> colors;
  final String colorMode; // ':', '=', '<='
  final Set<String> identity;
  final RangeValues mv;
  final String? format;
  final Set<String> rarities;
  final String? setCode;
  final String? setLabel;
  final String sort; // name, cmc, released, edhrec, rarity, power
  final bool sortAscending;

  const FilterState({
    this.nameText = '',
    this.types = const {},
    this.oracleText = '',
    this.colors = const {},
    this.colorMode = ':',
    this.identity = const {},
    this.mv = const RangeValues(0, 16),
    this.format,
    this.rarities = const {},
    this.setCode,
    this.setLabel,
    this.sort = 'name',
    this.sortAscending = true,
  });

  FilterState copyWith({
    String? nameText,
    Set<String>? types,
    String? oracleText,
    Set<String>? colors,
    String? colorMode,
    Set<String>? identity,
    RangeValues? mv,
    String? format,
    bool clearFormat = false,
    Set<String>? rarities,
    String? setCode,
    String? setLabel,
    bool clearSet = false,
    String? sort,
    bool? sortAscending,
  }) =>
      FilterState(
        nameText: nameText ?? this.nameText,
        types: types ?? this.types,
        oracleText: oracleText ?? this.oracleText,
        colors: colors ?? this.colors,
        colorMode: colorMode ?? this.colorMode,
        identity: identity ?? this.identity,
        mv: mv ?? this.mv,
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
    if (colors.isNotEmpty) {
      parts.add('c$colorMode${colors.join().toLowerCase()}');
    }
    if (identity.isNotEmpty) parts.add('id:${identity.join().toLowerCase()}');
    if (mv.start > 0) parts.add('mv>=${mv.start.round()}');
    if (mv.end < 16) parts.add('mv<=${mv.end.round()}');
    if (format != null) parts.add('f:$format');
    if (rarities.isNotEmpty) {
      parts.add(rarities.length == 1
          ? 'r:${rarities.first}'
          : '(${rarities.map((r) => 'r:$r').join(' or ')})');
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
          if (((m.group(1) ?? m.group(2))!).replaceAll('"', '').trim()
              case final t when t.isNotEmpty)
            t
      ];

  Map<String, dynamic> toJson() => {
        'nameText': nameText,
        'types': types.toList(),
        'oracleText': oracleText,
        'colors': colors.toList(),
        'colorMode': colorMode,
        'identity': identity.toList(),
        'mvStart': mv.start,
        'mvEnd': mv.end,
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
        colors: {...(json['colors'] as List? ?? const []).cast<String>()},
        colorMode: json['colorMode'] as String? ?? ':',
        identity: {...(json['identity'] as List? ?? const []).cast<String>()},
        mv: RangeValues(
          (json['mvStart'] as num? ?? 0).toDouble(),
          (json['mvEnd'] as num? ?? 16).toDouble(),
        ),
        format: json['format'] as String?,
        rarities: {...(json['rarities'] as List? ?? const []).cast<String>()},
        setCode: json['setCode'] as String?,
        setLabel: json['setLabel'] as String?,
        sort: json['sort'] as String? ?? 'name',
        sortAscending: json['sortAscending'] as bool? ?? true,
      );
}

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
        DefaultFilterNotifier.new);

class FilterNotifier extends Notifier<FilterState> {
  // Watching means a settings edit immediately becomes the active filter.
  @override
  FilterState build() => ref.watch(defaultFilterProvider);

  void set(FilterState next) => state = next;
  void reset() => state = ref.read(defaultFilterProvider);
}

final filterProvider =
    NotifierProvider<FilterNotifier, FilterState>(FilterNotifier.new);

// ----------------------------------------------------------- saved cards

/// Oracle ids the user bookmarked to view later, newest first. Persisted in
/// prefs (not the card DB, which gets replaced on every data update).
class SavedCardsNotifier extends Notifier<List<String>> {
  static const _key = 'savedCards';

  @override
  List<String> build() =>
      ref.watch(prefsProvider).getStringList(_key) ?? const [];

  bool isSaved(String oracleId) => state.contains(oracleId);

  void toggle(String oracleId) => isSaved(oracleId)
      ? remove(oracleId)
      : _set([oracleId, ...state]);

  void remove(String oracleId) =>
      _set([for (final id in state) if (id != oracleId) id]);

  void clear() => _set(const []);

  void _set(List<String> next) {
    state = next;
    ref.read(prefsProvider).setStringList(_key, next);
  }
}

final savedCardsProvider =
    NotifierProvider<SavedCardsNotifier, List<String>>(SavedCardsNotifier.new);

final savedCardSummariesProvider =
    FutureProvider<List<CardSummary>>((ref) async {
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
