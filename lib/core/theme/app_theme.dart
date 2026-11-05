import 'package:flutter/material.dart';

/// Dark, black-and-gold look: card rows, pill chips, gold accents.
class AppTheme {
  AppTheme._();

  static const gain = Color(0xFF16C784);
  static const loss = Color(0xFFEA3943);
  static const gold = Color(0xFFF5C518);

  static const _bg = Color(0xFF0B0B0C);
  static const _card = Color(0xFF161618);
  static const _cardHigh = Color(0xFF1F1F22);
  static const _muted = Color(0xFF8E8E93);

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: gold,
      onPrimary: Colors.black,
      secondary: gold,
      onSecondary: Colors.black,
      secondaryContainer: gold, // selected chips / nav indicator
      onSecondaryContainer: Colors.black,
      primaryContainer: Color(0xFF3A2F00),
      onPrimaryContainer: gold,
      surface: _bg,
      onSurface: Colors.white,
      surfaceContainerHigh: _card,
      surfaceContainerHighest: _cardHigh,
      outline: _muted,
      error: loss,
    );
    return _theme(scheme);
  }

  static ThemeData light() => _theme(
        ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.light).copyWith(
          secondaryContainer: gold,
          onSecondaryContainer: Colors.black,
        ),
      );

  static ThemeData _theme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHigh,
        labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: 0.2)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        hintStyle: TextStyle(color: scheme.outline),
        prefixIconColor: scheme.outline,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
      ),
    );
  }

  /// Green for gains, red for losses, neutral grey when unknown.
  static Color changeColor(double? pct) {
    if (pct == null || pct == 0) return Colors.grey;
    return pct > 0 ? gain : loss;
  }
}
