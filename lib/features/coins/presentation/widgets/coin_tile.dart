import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/coin_avatar.dart';
import '../../../../core/widgets/sparkline.dart';
import '../../../watchlist/presentation/bloc/watchlist_bloc.dart';
import '../../domain/coin.dart';

/// Card row: avatar, name/symbol, 7-day sparkline, price and 24h change.
class CoinTile extends StatelessWidget {
  const CoinTile({super.key, required this.coin});

  final Coin coin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = coin.priceChangePercentage24h;
    final changeColor = AppTheme.changeColor(change);
    final spark = coin.sparkline;
    final trendColor = spark.length >= 2 ? AppTheme.changeColor(spark.last - spark.first) : changeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/coin/${coin.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CoinAvatar(url: coin.image, symbol: coin.symbol, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(coin.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          // Only this star rebuilds when this coin's watched state flips.
                          BlocSelector<WatchlistBloc, WatchlistState, bool>(
                            selector: (s) => s.isWatched(coin.id),
                            builder: (context, watched) => InkResponse(
                              radius: 18,
                              onTap: () => context.read<WatchlistBloc>().add(WatchlistToggled(coin)),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  watched ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 18,
                                  semanticLabel: watched ? 'Remove from watchlist' : 'Add to watchlist',
                                  color: watched ? AppTheme.gold : theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(coin.symbol.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                if (spark.length >= 2) ...[
                  const SizedBox(width: 4),
                  Sparkline(data: spark, color: trendColor, width: 56),
                  const SizedBox(width: 12),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Fmt.price(coin.currentPrice),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(Fmt.percent(change),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: changeColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
