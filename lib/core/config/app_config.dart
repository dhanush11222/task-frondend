class AppConfig {
  AppConfig._();

  /// Deployed backend (Vercel). Used by default so the app works on any device.
  static const liveBaseUrl = 'https://task-backend-ten.vercel.app/api';

  /// Point at a local backend instead with:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api   (Android emulator)
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api (physical device)
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => _override.isNotEmpty ? _override : liveBaseUrl;

  /// Interval for silent "live price" refresh on the list screen.
  static const refreshInterval = Duration(seconds: 30);
  static const pageSize = 20;
}
