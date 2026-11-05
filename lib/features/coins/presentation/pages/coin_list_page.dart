import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/coin_query.dart';
import '../bloc/coin_list_bloc.dart';
import '../widgets/coin_tile.dart';

class CoinListPage extends StatefulWidget {
  const CoinListPage({super.key});

  @override
  State<CoinListPage> createState() => _CoinListPageState();
}

class _CoinListPageState extends State<CoinListPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // "Live" prices: silent background refresh every 30s.
    _timer = Timer.periodic(AppConfig.refreshInterval, (_) {
      if (mounted) context.read<CoinListBloc>().add(const CoinListReloadRequested(silent: true));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      context.read<CoinListBloc>().add(const CoinListLoadMore());
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<CoinListBloc>()..add(const CoinListReloadRequested());
    await bloc.stream.firstWhere((s) => s.status != CoinListStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, Trader',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
            const Text('Markets'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              // Tap anywhere outside: drop focus (stops the blinking cursor, closes the keyboard).
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              onChanged: (v) {
                setState(() {}); // toggles the clear button
                context.read<CoinListBloc>().add(CoinListSearchChanged(v));
              },
              decoration: InputDecoration(
                hintText: 'Search coins',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                          context.read<CoinListBloc>().add(const CoinListSearchChanged(''));
                        },
                      ),
              ),
            ),
          ),
          const _FilterSortBar(),
          BlocSelector<CoinListBloc, CoinListState, String?>(
            selector: (s) => s.source,
            builder: (_, source) => SourceBanner(source: source),
          ),
          Expanded(
            child: BlocConsumer<CoinListBloc, CoinListState>(
              listenWhen: (p, c) => p.status != c.status && c.status == CoinListStatus.failure && c.coins.isNotEmpty,
              listener: (context, state) => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.failure?.message ?? 'Refresh failed'))),
              builder: (context, state) {
                final bloc = context.read<CoinListBloc>();
                final loadingFirst = state.status == CoinListStatus.initial ||
                    (state.status == CoinListStatus.loading && state.coins.isEmpty);
                if (loadingFirst) return const ListSkeleton();

                if (state.status == CoinListStatus.failure && state.coins.isEmpty) {
                  return ErrorView(
                    failure: state.failure!,
                    onRetry: () => bloc.add(const CoinListReloadRequested()),
                  );
                }
                if (state.coins.isEmpty) {
                  return EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No coins found',
                    message: state.isSearchingOrFiltering
                        ? 'Try a different search or clear the filters.'
                        : 'There is nothing to show right now.',
                    actionLabel: state.isSearchingOrFiltering ? 'Clear filters' : 'Reload',
                    onAction: () {
                      _search.clear();
                      setState(() {});
                      bloc
                        ..add(const CoinListSearchChanged(''))
                        ..add(const CoinListFilterChanged(CoinFilter.all))
                        ..add(const CoinListReloadRequested());
                    },
                  );
                }

                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        controller: _scroll,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.coins.length + (state.hasMore || state.loadMoreFailed ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i < state.coins.length) return CoinTile(coin: state.coins[i]);
                          if (state.loadMoreFailed) {
                            return TextButton(
                              onPressed: () => bloc.add(const CoinListLoadMore()),
                              child: const Text('Couldn’t load more. Tap to retry'),
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      ),
                    ),
                    if (state.status == CoinListStatus.loading)
                      const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSortBar extends StatelessWidget {
  const _FilterSortBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinListBloc, CoinListState>(
      buildWhen: (p, c) => p.filter != c.filter || p.sort != c.sort || p.ascending != c.ascending,
      builder: (context, state) {
        final bloc = context.read<CoinListBloc>();
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final f in CoinFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: state.filter == f,
                    onSelected: (_) => bloc.add(CoinListFilterChanged(f)),
                  ),
                ),
              const VerticalDivider(width: 16, indent: 8, endIndent: 8),
              PopupMenuButton<CoinSort>(
                tooltip: 'Sort by',
                onSelected: (s) => bloc.add(CoinListSortChanged(s)),
                itemBuilder: (_) => [
                  for (final s in CoinSort.values)
                    CheckedPopupMenuItem(value: s, checked: s == state.sort, child: Text(s.label)),
                ],
                child: Chip(
                  avatar: const Icon(Icons.sort_rounded, size: 18),
                  label: Text(state.sort.label),
                ),
              ),
              const SizedBox(width: 8),
              ActionChip(
                tooltip: state.ascending ? 'Ascending' : 'Descending',
                label: Icon(state.ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 18),
                onPressed: () => bloc.add(CoinListSortChanged(state.sort, ascending: !state.ascending)),
              ),
            ],
          ),
        );
      },
    );
  }
}
