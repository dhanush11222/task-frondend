import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/coin_avatar.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../coins/domain/coin.dart';
import '../../../watchlist/presentation/bloc/watchlist_bloc.dart';
import '../../domain/coin_detail.dart';
import '../bloc/coin_detail_bloc.dart';
import '../widgets/price_chart.dart';

class CoinDetailPage extends StatelessWidget {
  const CoinDetailPage({super.key, required this.coinId});

  final String coinId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CoinDetailBloc>(param1: coinId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinDetailBloc, CoinDetailState>(
      buildWhen: (p, c) => p.detailStatus != c.detailStatus || p.detail != c.detail,
      builder: (context, state) {
        final bloc = context.read<CoinDetailBloc>();
        return Scaffold(
          appBar: AppBar(title: const Text('Details Coin'), centerTitle: true),
          body: switch (state.detailStatus) {
            LoadStatus.loading => const Center(child: CircularProgressIndicator()),
            LoadStatus.failure => ErrorView(
                failure: state.detailFailure!,
                onRetry: () => bloc.add(const CoinDetailRequested()),
              ),
            LoadStatus.success => RefreshIndicator(
                onRefresh: () async {
                  bloc
                    ..add(const CoinDetailRequested())
                    ..add(CoinChartRequested(bloc.state.range));
                  await bloc.stream.firstWhere((s) => s.detailStatus != LoadStatus.loading);
                },
                child: _Content(detail: state.detail!),
              ),
          },
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.detail});

  final CoinDetail detail;

  @override
  Widget build(BuildContext context) {
    final coin = detail.coin;
    final theme = Theme.of(context);
    final change = coin.priceChangePercentage24h;
    final changeColor = AppTheme.changeColor(change);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Header + chart live in one card, like the reference design.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CoinAvatar(url: coin.image, symbol: coin.symbol, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(coin.symbol.toUpperCase(),
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          Text(coin.name.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.outline, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    BlocSelector<WatchlistBloc, WatchlistState, bool>(
                      selector: (s) => s.isWatched(coin.id),
                      builder: (context, watched) => IconButton.outlined(
                        tooltip: watched ? 'Remove from watchlist' : 'Add to watchlist',
                        icon: Icon(watched ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: watched ? AppTheme.gold : null),
                        onPressed: () => context.read<WatchlistBloc>().add(WatchlistToggled(coin)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(Fmt.price(coin.currentPrice),
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (change != null && change != 0)
                      Icon(change > 0 ? Icons.north_east_rounded : Icons.south_east_rounded,
                          size: 14, color: changeColor),
                    const SizedBox(width: 2),
                    Text('${Fmt.percent(change)}  (24h)',
                        style: TextStyle(color: changeColor, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('Rank #${coin.marketCapRank ?? '-'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 20),
                const _ChartSection(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Market Stats', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _StatsGrid(coin: coin),
        if (detail.description.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('About ${coin.name}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _ExpandableText(detail.description),
        ],
      ],
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoinDetailBloc, CoinDetailState>(
      buildWhen: (p, c) => p.chartStatus != c.chartStatus || p.chart != c.chart || p.range != c.range,
      builder: (context, state) {
        final bloc = context.read<CoinDetailBloc>();
        final body = switch (state.chartStatus) {
          LoadStatus.loading => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          LoadStatus.failure => ErrorView(
              failure: state.chartFailure!,
              onRetry: () => bloc.add(CoinChartRequested(state.range)),
            ),
          LoadStatus.success => state.chart.length < 2
              ? const EmptyView(
                  icon: Icons.show_chart_rounded,
                  title: 'No chart data',
                  message: 'Price history is unavailable for this range.',
                )
              : PriceChart(points: state.chart, days: state.range.days),
        };
        return Column(
          children: [
            SizedBox(height: 240, child: body),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final r in ChartRange.values)
                  ChoiceChip(
                    label: Text(r.label),
                    selected: state.range == r,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                    onSelected: (_) => bloc.add(CoinChartRequested(r)),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Market cap', Fmt.fullCurrency(coin.marketCap)),
      ('24h volume', Fmt.fullCurrency(coin.totalVolume)),
      ('24h high', Fmt.price(coin.high24h)),
      ('24h low', Fmt.price(coin.low24h)),
      ('Circulating supply', Fmt.supply(coin.circulatingSupply, symbol: coin.symbol)),
      ('Total supply', Fmt.supply(coin.totalSupply, symbol: coin.symbol)),
      ('Max supply', Fmt.supply(coin.maxSupply, symbol: coin.symbol, nullAsInfinity: true)),
      ('All-time high', Fmt.price(coin.ath)),
      ('From ATH', Fmt.percent(coin.athChangePercentage)),
    ];
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(rows[i].$1, style: TextStyle(color: theme.colorScheme.outline)),
                    Flexible(
                      child: Text(rows[i].$2,
                          textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.text, maxLines: _expanded ? null : 5, overflow: _expanded ? null : TextOverflow.ellipsis),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Show less' : 'Read more'),
        ),
      ],
    );
  }
}
