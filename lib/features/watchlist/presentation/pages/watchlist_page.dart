import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../coins/presentation/widgets/coin_tile.dart';
import '../bloc/watchlist_bloc.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Live prices: refresh quietly every 30s.
    _timer = Timer.periodic(AppConfig.refreshInterval, (_) {
      if (mounted) context.read<WatchlistBloc>().add(const WatchlistRequested(silent: true));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: BlocBuilder<WatchlistBloc, WatchlistState>(
        builder: (context, state) {
          final bloc = context.read<WatchlistBloc>();
          if (state.status == WatchlistStatus.loading) return const ListSkeleton(itemCount: 5);
          if (state.coins.isEmpty) {
            return EmptyView(
              icon: Icons.star_outline_rounded,
              title: 'Your watchlist is empty',
              message: 'Tap the star on any coin to track it here.',
              actionLabel: 'Browse markets',
              onAction: () => context.go('/'),
            );
          }
          return Column(
            children: [
              if (state.stale)
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  child: Text(
                    'Offline: showing last saved prices',
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    bloc.add(const WatchlistRequested(silent: true));
                    await bloc.stream.first;
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
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(Icons.delete_outline_rounded),
                        ),
                        onDismissed: (_) => bloc.add(WatchlistToggled(coin)),
                        child: CoinTile(coin: coin),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
