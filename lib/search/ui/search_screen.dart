import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/errors.dart';
import 'card_tile.dart';
import 'filter_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchProvider).query;
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        ref.read(searchProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    // Short coalescing window only — results paint without waiting on the
    // match count, so this feels effectively instant while typing.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      ref.read(searchProvider.notifier).setQuery(text);
    });
  }

  void _clearAll() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(filterProvider.notifier).reset();
    ref.read(searchProvider.notifier).setQuery('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);
    final updateAvailable =
        ref.watch(updateAvailableProvider).valueOrNull ?? false;

    // Keep the box in sync when the query changes programmatically (live
    // filter edits), without fighting the cursor while the user is typing.
    ref.listen<String>(searchProvider.select((s) => s.query), (_, next) {
      if (!_focus.hasFocus && _controller.text != next) {
        _controller.text = next;
        _controller.selection =
            TextSelection.collapsed(offset: next.length);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          onChanged: _onChanged,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Search or use filters',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear',
              onPressed: _clearAll,
            ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Saved cards',
            onPressed: () => context.push('/saved'),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filters & sort',
            // Filters apply live; the box stays synced via the listener above.
            onPressed: () => showFilterSheet(context, ref),
          ),
          PopupMenuButton<String>(
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/settings', child: Text('Settings')),
              PopupMenuItem(value: '/data', child: Text('Card data & updates')),
              PopupMenuItem(
                value: '/about',
                child: Text('About & attribution'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (updateAvailable) const _UpdateBanner(),
          if (search.error != null)
            _QueryErrorBanner(error: search.error!, query: search.query),
          if (search.error == null && !search.loading && search.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  // total is null until the count query lands; results are
                  // already showing, so just say "cards" until it arrives.
                  search.total == null
                      ? 'cards'
                      : '${search.total} card${search.total == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(child: _buildBody(search)),
        ],
      ),
    );
  }

  Widget _buildBody(SearchState search) {
    if (search.error != null) {
      return const SizedBox.shrink();
    }
    if (search.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (search.items.isEmpty) {
      return const Center(child: Text('No cards match this search.'));
    }
    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        childAspectRatio: 488 / 680, // Scryfall 'normal' image ratio
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: search.items.length + (search.loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= search.items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        final card = search.items[i];
        return CardTile(card: card);
      },
    );
  }
}

class _QueryErrorBanner extends StatelessWidget {
  final QueryError error;
  final String query;

  const _QueryErrorBanner({required this.error, required this.query});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final position = error.position;
    return Container(
      width: double.infinity,
      color: scheme.errorContainer,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(error.message, style: TextStyle(color: scheme.onErrorContainer)),
          if (position != null && position <= query.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$query\n${' ' * position}^',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialBanner(
      content: const Text('Updated card data is available.'),
      actions: [
        TextButton(
          onPressed: () => context.push('/data'),
          child: const Text('Update'),
        ),
        TextButton(
          onPressed: () => ref.invalidate(updateAvailableProvider),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
