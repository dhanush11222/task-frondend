import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/state_views.dart';
import '../../../coins/presentation/widgets/coin_tile.dart';
import '../bloc/watchlist_bloc.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: BlocBuilder<WatchlistBloc, WatchlistState>(
        builder: (context, state) {
          final bloc = context.read<WatchlistBloc>();
          if (state.status == WatchlistStatus.loading && state.coins.isEmpty) return const ListSkeleton(itemCount: 5);
          if (state.status == WatchlistStatus.failure && state.coins.isEmpty) {
            return ErrorView(failure: state.failure!, onRetry: () => bloc.add(const WatchlistRequested()));
          }
          if (state.coins.isEmpty) {
            return EmptyView(
              icon: Icons.star_outline_rounded,
              title: 'Your watchlist is empty',
              message: 'Tap the star on any coin to track it here.',
              actionLabel: 'Browse markets',
              onAction: () => context.go('/'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              bloc.add(const WatchlistRequested());
              await bloc.stream.firstWhere((s) => s.status != WatchlistStatus.loading);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.coins.length,
              itemBuilder: (context, i) {
                final coin = state.coins[i];
                return Dismissible(
                  key: ValueKey(coin.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_outline_rounded),
                  ),
                  onDismissed: (_) => bloc.add(WatchlistToggled(coin)),
                  child: CoinTile(coin: coin),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
