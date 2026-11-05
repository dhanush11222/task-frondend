import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../coin_detail/domain/coin_detail.dart';
import '../../market_stats/domain/market_stats.dart';
import '../domain/coin.dart';
import '../domain/coin_query.dart';

double? _d(dynamic v) => (v as num?)?.toDouble();

Coin coinFromJson(Map<String, dynamic> j) => Coin(
      id: j['id'] as String,
      symbol: j['symbol'] as String,
      name: j['name'] as String,
      image: j['image'] as String?,
      currentPrice: _d(j['currentPrice']),
      marketCap: _d(j['marketCap']),
      marketCapRank: (j['marketCapRank'] as num?)?.toInt(),
      totalVolume: _d(j['totalVolume']),
      priceChangePercentage24h: _d(j['priceChangePercentage24h']),
      high24h: _d(j['high24h']),
      low24h: _d(j['low24h']),
      circulatingSupply: _d(j['circulatingSupply']),
      totalSupply: _d(j['totalSupply']),
      maxSupply: _d(j['maxSupply']),
      ath: _d(j['ath']),
      athChangePercentage: _d(j['athChangePercentage']),
    );

List<Coin> coinsFromJson(dynamic list) =>
    (list as List).map((e) => coinFromJson(e as Map<String, dynamic>)).toList();

class CoinsRepository {
  CoinsRepository(this._api);

  final ApiClient _api;

  Future<CoinPage> getCoins({
    int page = 1,
    int perPage = AppConfig.pageSize,
    String search = '',
    CoinSort sort = CoinSort.marketCap,
    bool ascending = false,
    CoinFilter filter = CoinFilter.all,
  }) async {
    final res = await _api.get('/coins', query: {
      'page': page,
      'perPage': perPage,
      if (search.trim().isNotEmpty) 'search': search.trim(),
      'sort': sort.apiValue,
      'order': ascending ? 'asc' : 'desc',
      'filter': filter.apiValue,
    });
    return CoinPage(
      coins: _parse(() => coinsFromJson(res.data)),
      hasMore: res.meta['hasMore'] as bool? ?? false,
      total: (res.meta['total'] as num?)?.toInt() ?? 0,
      source: res.meta['source'] as String? ?? 'live',
    );
  }

  Future<CoinDetail> getCoinDetail(String id) async {
    final res = await _api.get('/coins/$id');
    return _parse(() {
      final j = res.data as Map<String, dynamic>;
      return CoinDetail(
        coin: coinFromJson(j),
        description: j['description'] as String? ?? '',
        categories: ((j['categories'] as List?) ?? const []).cast<String>(),
        homepage: j['homepage'] as String?,
      );
    });
  }

  Future<List<ChartPoint>> getChart(String id, int days) async {
    final res = await _api.get('/coins/$id/chart', query: {'days': days});
    return _parse(() => (res.data as List).map((e) {
          final m = e as Map<String, dynamic>;
          return ChartPoint(
            DateTime.fromMillisecondsSinceEpoch((m['timestamp'] as num).toInt()),
            (m['price'] as num).toDouble(),
          );
        }).toList());
  }

  Future<MarketStats> getMarketStats() async {
    final res = await _api.get('/market/stats');
    return _parse(() {
      final j = res.data as Map<String, dynamic>;
      return MarketStats(
        totalMarketCap: _d(j['totalMarketCap']) ?? 0,
        totalVolume24h: _d(j['totalVolume24h']) ?? 0,
        marketCapChange24h: _d(j['marketCapChangePercentage24h']),
        btcDominance: _d(j['btcDominance']),
        activeCryptocurrencies: (j['activeCryptocurrencies'] as num?)?.toInt() ?? 0,
        topGainers: coinsFromJson(j['topGainers']),
        topLosers: coinsFromJson(j['topLosers']),
      );
    });
  }

  /// Malformed JSON becomes a Failure instead of crashing the bloc.
  T _parse<T>(T Function() fn) {
    try {
      return fn();
    } catch (_) {
      throw const Failure('Received unexpected data from the server.');
    }
  }
}
