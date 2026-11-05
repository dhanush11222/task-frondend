import 'coin.dart';

enum CoinSort {
  marketCap('market_cap', 'Market cap'),
  price('price', 'Price'),
  volume('volume', 'Volume'),
  change24h('change_24h', '24h change');

  const CoinSort(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

enum CoinFilter {
  all('all', 'All'),
  gainers('gainers', 'Gainers'),
  losers('losers', 'Losers');

  const CoinFilter(this.apiValue, this.label);
  final String apiValue;
  final String label;
}

class CoinPage {
  const CoinPage({required this.coins, required this.hasMore, required this.total, required this.source});

  final List<Coin> coins;
  final bool hasMore;
  final int total;
  final String source;
}
