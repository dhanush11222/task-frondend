import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/coin_detail/presentation/pages/coin_detail_page.dart';
import '../../features/coins/presentation/bloc/coin_list_bloc.dart';
import '../../features/coins/presentation/pages/coin_list_page.dart';
import '../../features/market_stats/presentation/bloc/market_stats_bloc.dart';
import '../../features/market_stats/presentation/pages/market_stats_page.dart';
import '../../features/watchlist/presentation/bloc/watchlist_bloc.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';
import '../di/injection.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => BlocProvider(
              create: (_) => sl<CoinListBloc>()..add(const CoinListReloadRequested()),
              child: const CoinListPage(),
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/stats',
            builder: (_, __) => BlocProvider(
              create: (_) => sl<MarketStatsBloc>()..add(const MarketStatsRequested()),
              child: const MarketStatsPage(),
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/watchlist', builder: (_, __) => const WatchlistPage()),
        ]),
      ],
    ),
    GoRoute(
      path: '/coin/:id',
      builder: (_, state) => CoinDetailPage(coinId: state.pathParameters['id']!),
    ),
  ],
);

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return BlocListener<WatchlistBloc, WatchlistState>(
      listenWhen: (p, c) => p.messageId != c.messageId && c.message != null,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Watchlist update failed: ${state.message}'))),
      // Back on Stats/Watchlist returns to Markets; back on Markets exits the app.
      child: PopScope(
        canPop: shell.currentIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) shell.goBranch(0);
        },
        child: Scaffold(
          body: shell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.show_chart_rounded), label: 'Markets'),
              NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'Stats'),
              NavigationDestination(icon: Icon(Icons.star_rounded), label: 'Watchlist'),
            ],
          ),
        ),
      ),
    );
  }
}
