import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  /// Override with: flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    // Android emulator reaches the host machine via 10.0.2.2.
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  /// Interval for silent "live price" refresh on the list screen.
  static const refreshInterval = Duration(seconds: 30);
  static const pageSize = 20;
}
