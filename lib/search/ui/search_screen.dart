import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/errors.dart';
import '../../data/repo/card_repository.dart';
import 'filter_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
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
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchProvider.notifier).setQuery(text);
    });
  }

  void _appendSyntax(String syntax) {
    final current = _controller.text.trim();
    _controller.text = current.isEmpty ? syntax : '$current $syntax';
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
    ref.read(searchProvider.notifier).setQuery(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);
    final updateAvailable =
        ref.watch(updateAvailableProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          onChanged: _onChanged,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            hintText: 't:creature c:rg mv<=3 o:"draw a card"',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchProvider.notifier).setQuery('');
                setState(() {});
              },
            ),
          _SortMenu(onSelected: _appendSyntax),
          PopupMenuButton<String>(
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/data', child: Text('Card data & updates')),
              PopupMenuItem(value: '/about', child: Text('About & attribution')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Filters',
        onPressed: () async {
          final syntax = await showFilterSheet(context, ref);
          if (syntax != null && syntax.isNotEmpty) _appendSyntax(syntax);
        },
        child: const Icon(Icons.tune),
      ),
      body: Column(
        children: [
          if (updateAvailable) const _UpdateBanner(),
          if (search.error != null)
            _QueryErrorBanner(error: search.error!, query: search.query),
          if (search.error == null && search.query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${search.total} card${search.total == 1 ? '' : 's'}',
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
    if (search.query.isEmpty) {
      return const _EmptyHint();
    }
    if (search.error != null) {
      return const SizedBox.shrink();
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
        return _CardTile(card: card);
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardSummary card;

  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/card/${card.oracleId}'),
      borderRadius: BorderRadius.circular(9),
      child: card.imageNormal == null
          ? _TextFallback(card: card)
          : ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: CachedNetworkImage(
                imageUrl: card.imageNormal!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _TextFallback(card: card),
                errorWidget: (_, __, ___) => _TextFallback(card: card),
              ),
            ),
    );
  }
}

class _TextFallback extends StatelessWidget {
  final CardSummary card;

  const _TextFallback({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.name,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall),
          if (card.manaCost != null)
            Text(card.manaCost!,
                style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(card.typeLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
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
          Text(error.message,
              style: TextStyle(color: scheme.onErrorContainer)),
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

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 48),
            const SizedBox(height: 12),
            Text('Search with Scryfall syntax',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              't:creature c:rg mv<=3\no:"enters tapped" -t:land\n'
              'pow>tou f:commander\n!"Lightning Bolt"',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text('or tap the filter button below'),
          ],
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final void Function(String syntax) onSelected;

  const _SortMenu({required this.onSelected});

  static const _sorts = {
    'Name': 'order:name',
    'Mana value': 'order:cmc',
    'Newest first': 'order:released',
    'EDHREC rank': 'order:edhrec',
    'Rarity': 'order:rarity',
    'Power': 'order:power',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort',
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final e in _sorts.entries)
          PopupMenuItem(value: e.value, child: Text(e.key)),
      ],
    );
  }
}
