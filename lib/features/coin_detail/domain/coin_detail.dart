import 'package:equatable/equatable.dart';

import '../../coins/domain/coin.dart';

class CoinDetail extends Equatable {
  const CoinDetail({
    required this.coin,
    this.description = '',
    this.categories = const [],
    this.homepage,
  });

  final Coin coin;
  final String description;
  final List<String> categories;
  final String? homepage;

  @override
  List<Object?> get props => [coin, description];
}

class ChartPoint extends Equatable {
  const ChartPoint(this.timestamp, this.price);

  final DateTime timestamp;
  final double price;

  @override
  List<Object?> get props => [timestamp, price];
}

enum ChartRange {
  day('1D', 1),
  week('7D', 7),
  month('1M', 30),
  quarter('3M', 90),
  year('1Y', 365);

  const ChartRange(this.label, this.days);
  final String label;
  final int days;
}
