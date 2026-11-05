import 'package:equatable/equatable.dart';

import '../../coins/domain/coin.dart';

class MarketStats extends Equatable {
  const MarketStats({
    required this.totalMarketCap,
    required this.totalVolume24h,
    required this.activeCryptocurrencies,
    required this.topGainers,
    required this.topLosers,
    this.marketCapChange24h,
    this.btcDominance,
  });

  final double totalMarketCap;
  final double totalVolume24h;
  final double? marketCapChange24h;
  final double? btcDominance;
  final int activeCryptocurrencies;
  final List<Coin> topGainers;
  final List<Coin> topLosers;

  @override
  List<Object?> get props => [totalMarketCap, totalVolume24h, btcDominance, topGainers, topLosers];
}
