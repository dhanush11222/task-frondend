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
  hour('1H', 1, Duration(hours: 1)),
  day('24H', 1),
  week('7D', 7),
  month('30D', 30),
  year('1Y', 365);

  const ChartRange(this.label, this.days, [this.window]);
  final String label;

  /// Days of history requested from the API.
  final int days;

  /// If set, only the most recent [window] of the fetched data is shown (1H is a slice of the 1-day series).
  final Duration? window;
}
