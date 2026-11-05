import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/coin_avatar.dart';
import '../../../watchlist/presentation/bloc/watchlist_bloc.dart';
import '../../domain/coin.dart';

class CoinTile extends StatelessWidget {
  const CoinTile({super.key, required this.coin, this.showRank = true});

  final Coin coin;
  final bool showRank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = coin.priceChangePercentage24h;
    final changeColor = AppTheme.changeColor(change);

    return InkWell(
      onTap: () => context.push('/coin/${coin.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            // Star toggle only rebuilds when this coin's watched state flips.
            BlocSelector<WatchlistBloc, WatchlistState, bool>(
              selector: (s) => s.isWatched(coin.id),
              builder: (context, watched) => IconButton(
                tooltip: watched ? 'Remove from watchlist' : 'Add to watchlist',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  watched ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: watched ? Colors.amber : theme.colorScheme.outline,
                ),
                onPressed: () => context.read<WatchlistBloc>().add(WatchlistToggled(coin)),
              ),
            ),
            if (showRank)
              SizedBox(
                width: 28,
                child: Text(
                  '${coin.marketCapRank ?? '-'}',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            CoinAvatar(url: coin.image, symbol: coin.symbol, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coin.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${coin.symbol.toUpperCase()} · MCap ${Fmt.compactCurrency(coin.marketCap)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.price(coin.currentPrice),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(Fmt.percent(change),
                    style: theme.textTheme.bodySmall?.copyWith(color: changeColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
