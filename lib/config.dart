import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Application configuration with dynamic backend URL support.
///
/// NOTE FOR TESTING ON REAL PHONES:
/// When running on a physical phone, "localhost" refers to the phone itself,
/// not your computer. Set [defaultBaseUrl] or configure in the app settings modal
/// to your computer's local Wi-Fi IP address (e.g. "http://192.168.1.50:8000").
abstract final class AppConfig {
  static const String _prefKeyBaseUrl = 'voiceai_backend_base_url';

  /// Default backend URL depending on the platform:
  /// - Android emulator uses 10.0.2.2 to reach host machine
  /// - Desktop/Web uses localhost:8000
  /// - Physical device can be configured in settings or set here directly
  static String get defaultBaseUrl {
    return 'https://mobile-app-w44p.onrender.com';
  }

  static String _activeBaseUrl = defaultBaseUrl;

  /// The currently active base URL
  static String get baseUrl => _activeBaseUrl;

  /// Initialize config from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefKeyBaseUrl);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _activeBaseUrl = savedUrl.trim();
      } else {
        _activeBaseUrl = defaultBaseUrl;
      }
    } catch (_) {
      _activeBaseUrl = defaultBaseUrl;
    }
  }

  /// Update the base URL and persist it
  static Future<void> setBaseUrl(String newUrl) async {
    final cleanUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _activeBaseUrl = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyBaseUrl, cleanUrl);
    } catch (_) {}
  }

  /// Reset to platform default
  static Future<void> resetToDefault() async {
    _activeBaseUrl = defaultBaseUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyBaseUrl);
    } catch (_) {}
  }
}
