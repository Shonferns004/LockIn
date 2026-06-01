class AppConstants {
  AppConstants._();

  /// Base URL of the backend API (no trailing slash, no /api).
  /// Override at build time: flutter run --dart-define=BACKEND_URL=http://IP:2100
  /// - Android emulator: 10.0.2.2 (maps to host)
  /// - Physical phone: use your machine's LAN IP
  /// - Production: use your hosted backend URL
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.28.242.66:2100',
  );

  static String get apiUrl => '$backendUrl/api';
}
