class AppConstants {
  AppConstants._();

  /// Full base URL of the backend (including /api if needed).
  /// Override at build time: flutter run --dart-define=BACKEND_URL=http://IP:2100
  /// - Local: http://10.28.242.66:2100
  /// - Android emulator: http://10.0.2.2:2100
  /// - Production: https://your-domain.com
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://lock-in-server.vercel.app',
  );

  /// API endpoint root (no trailing slash).
  static String get apiUrl => backendUrl;
}
