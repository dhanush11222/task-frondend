import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../coins/domain/coin.dart';
import '../../../coins/presentation/widgets/coin_tile.dart';
import '../../domain/market_stats.dart';
import '../bloc/market_stats_bloc.dart';

class MarketStatsPage extends StatefulWidget {
  const MarketStatsPage({super.key});

  @override
  State<MarketStatsPage> createState() => _MarketStatsPageState();
}

class _MarketStatsPageState extends State<MarketStatsPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(AppConfig.refreshInterval, (_) {
      if (mounted) context.read<MarketStatsBloc>().add(const MarketStatsRequested(silent: true));
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
      appBar: AppBar(title: const Text('Market stats')),
      body: BlocBuilder<MarketStatsBloc, MarketStatsState>(
        builder: (context, state) {
          final bloc = context.read<MarketStatsBloc>();
          if (state.stats == null) {
            return switch (state.status) {
              MarketStatsStatus.failure => ErrorView(
                  failure: state.failure!,
                  onRetry: () => bloc.add(const MarketStatsRequested()),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            };
          }
          final s = state.stats!;
          return RefreshIndicator(
            onRefresh: () async {
              bloc.add(const MarketStatsRequested(silent: true));
              await bloc.stream.firstWhere((x) => x.status != MarketStatsStatus.loading);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _Overview(stats: s),
                const SizedBox(height: 24),
                _MoversSection(title: 'Top gainers', coins: s.topGainers),
                const SizedBox(height: 16),
                _MoversSection(title: 'Top losers', coins: s.topLosers),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.stats});

  final MarketStats stats;

  @override
  Widget build(BuildContext context) {
    final change = stats.marketCapChange24h;
    final tiles = <Widget>[
      _StatCard(
        label: 'Total market cap',
        value: Fmt.compactCurrency(stats.totalMarketCap),
        sub: change == null ? null : Fmt.percent(change),
        subColor: AppTheme.changeColor(change),
      ),
      _StatCard(label: '24h volume', value: Fmt.compactCurrency(stats.totalVolume24h)),
      _StatCard(
        label: 'BTC dominance',
        value: stats.btcDominance == null ? '—' : '${stats.btcDominance!.toStringAsFixed(1)}%',
      ),
      _StatCard(label: 'Active coins', value: Fmt.supply(stats.activeCryptocurrencies.toDouble())),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: tiles,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.sub, this.subColor});

  final String label;
  final String value;
  final String? sub;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (sub != null)
              Text(sub!, style: theme.textTheme.bodySmall?.copyWith(color: subColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MoversSection extends StatelessWidget {
  const _MoversSection({required this.title, required this.coins});

  final String title;
  final List<Coin> coins;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (coins.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('No data'))
        else
          for (final c in coins) CoinTile(coin: c),
      ],
    );
  }
}
