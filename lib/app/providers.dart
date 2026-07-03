import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/errors.dart';
import '../data/db/database.dart';
import '../data/db/db_files.dart';
import '../data/repo/card_repository.dart';
import '../data/sync/sync_progress.dart';
import '../data/sync/sync_repository.dart';
import '../search/compiler/sql_compiler.dart';
import '../search/parser/grammar.dart';

/// Overridden in main() after platform directories resolve.
final dbFilesProvider =
    Provider<DbFiles>((ref) => throw UnimplementedError('set in main()'));
final appVersionProvider =
    Provider<String>((ref) => throw UnimplementedError('set in main()'));

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

/// True when a newer bulk file exists upstream (checked at most once per
/// app session by the search screen).
final updateAvailableProvider = FutureProvider<bool>((ref) async {
  final meta = await ref.watch(metaProvider.future);
  final current = meta['bulkUpdatedAt'];
  if (current == null) return false;
  final last = DateTime.tryParse(meta['lastCheckAt'] ?? '');
  if (last != null &&
      DateTime.now().toUtc().difference(last.toUtc()).inHours < 24) {
    return false;
  }
  final repo = SyncRepository(
    files: ref.read(dbFilesProvider),
    client: ref.read(httpClientProvider),
    appVersion: ref.read(appVersionProvider),
  );
  try {
    return await repo.updateAvailable(current);
  } catch (_) {
    return false; // offline — never block the app on this
  }
});

// ---------------------------------------------------------------- search

const searchPageSize = 60;

class SearchState {
  final String query;
  final List<CardSummary> items;
  final int total;
  final bool loadingMore;
  final QueryError? error;

  const SearchState({
    this.query = '',
    this.items = const [],
    this.total = 0,
    this.loadingMore = false,
    this.error,
  });

  bool get hasMore => items.length < total;

  SearchState copyWith({
    String? query,
    List<CardSummary>? items,
    int? total,
    bool? loadingMore,
    QueryError? error,
  }) =>
      SearchState(
        query: query ?? this.query,
        items: items ?? this.items,
        total: total ?? this.total,
        loadingMore: loadingMore ?? this.loadingMore,
        error: error,
      );
}

class SearchNotifier extends Notifier<SearchState> {
  int _generation = 0;

  @override
  SearchState build() {
    ref.watch(cardRepositoryProvider); // reset on DB swap
    return const SearchState();
  }

  Future<void> setQuery(String query) async {
    final gen = ++_generation;
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    final repo = ref.read(cardRepositoryProvider);
    if (repo == null) return;
    try {
      final compiled = SqlCompiler.compile(ScryfallQueryParser.parse(query));
      final page =
          await repo.search(compiled, limit: searchPageSize, offset: 0);
      if (gen != _generation) return; // superseded by newer keystroke
      state = SearchState(query: query, items: page.items, total: page.total);
    } on QueryError catch (e) {
      if (gen != _generation) return;
      state = SearchState(query: query, error: e);
    }
  }

  Future<void> loadMore() async {
    final s = state;
    if (s.loadingMore || !s.hasMore || s.error != null) return;
    final repo = ref.read(cardRepositoryProvider);
    if (repo == null) return;
    final gen = _generation;
    state = s.copyWith(loadingMore: true);
    try {
      final compiled =
          SqlCompiler.compile(ScryfallQueryParser.parse(s.query));
      final page = await repo.search(compiled,
          limit: searchPageSize, offset: s.items.length);
      if (gen != _generation) return;
      state = state.copyWith(
        items: [...s.items, ...page.items],
        total: page.total,
        loadingMore: false,
      );
    } on QueryError {
      if (gen != _generation) return;
      state = state.copyWith(loadingMore: false);
    }
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

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
