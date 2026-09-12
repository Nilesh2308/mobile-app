/// Application configuration with permanent cloud backend.
abstract final class AppConfig {
  /// Permanent cloud backend hosted 24/7 on Render
  static const String baseUrl = 'https://mobile-app-w44p.onrender.com';

  /// Initialization hook
  static Future<void> init() async {}
}
