import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static const _dash = '—';

  /// Price with adaptive precision (BTC -> 2dp, SHIB -> 8dp).
  static String price(double? v) {
    if (v == null) return _dash;
    final digits = v >= 1 ? 2 : (v >= 0.01 ? 4 : (v >= 0.0001 ? 6 : 8));
    return NumberFormat.currency(symbol: r'$', decimalDigits: digits).format(v);
  }

  static String compactCurrency(double? v) {
    if (v == null) return _dash;
    return NumberFormat.compactCurrency(symbol: r'$', decimalDigits: 2).format(v);
  }

  static String fullCurrency(double? v) {
    if (v == null) return _dash;
    return NumberFormat.currency(symbol: r'$', decimalDigits: 0).format(v);
  }

  /// Coin quantities. [nullAsInfinity] is used for max supply (null = uncapped).
  static String supply(double? v, {String symbol = '', bool nullAsInfinity = false}) {
    if (v == null) return nullAsInfinity ? '∞' : _dash;
    final text = NumberFormat.compact().format(v);
    return symbol.isEmpty ? text : '$text ${symbol.toUpperCase()}';
  }

  static String percent(double? v) {
    if (v == null) return _dash;
    return '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
  }

  static String chartDate(DateTime d, int days) {
    if (days <= 1) return DateFormat('HH:mm').format(d);
    if (days <= 7) return DateFormat('MMM d, HH:mm').format(d);
    return DateFormat('MMM d, yyyy').format(d);
  }
}
