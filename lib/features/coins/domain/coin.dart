import 'package:equatable/equatable.dart';

class Coin extends Equatable {
  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    this.currentPrice,
    this.marketCap,
    this.marketCapRank,
    this.totalVolume,
    this.priceChangePercentage24h,
    this.high24h,
    this.low24h,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.ath,
    this.athChangePercentage,
    this.sparkline = const [],
  });

  final String id;
  final String symbol;
  final String name;
  final String? image;
  final double? currentPrice;
  final double? marketCap;
  final int? marketCapRank;
  final double? totalVolume;
  final double? priceChangePercentage24h;
  final double? high24h;
  final double? low24h;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final double? ath;
  final double? athChangePercentage;

  /// ~7-day price trend for list rows (empty when the backend doesn't send it).
  final List<double> sparkline;

  @override
  List<Object?> get props => [id, currentPrice, marketCap, totalVolume, priceChangePercentage24h];
}
