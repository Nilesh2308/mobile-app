import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Manages persistent session_id lifecycle across app launches.
/// Used across Chat and Voice Assistant for conversational continuity with FastAPI backend.
class SessionService {
  static const String _prefKeySessionId = 'voiceai_persistent_session_id';
  static const Uuid _uuid = Uuid();

  String? _currentSessionId;

  String get sessionId => _currentSessionId ?? '';

  /// Initialize and load or generate session ID
  Future<String> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? existing = prefs.getString(_prefKeySessionId);

    if (existing == null || existing.trim().isEmpty) {
      existing = _generateNewId();
      await prefs.setString(_prefKeySessionId, existing);
    }

    _currentSessionId = existing;
    return existing;
  }

  /// Regenerates a fresh session ID (clearing server-side conversation memory)
  Future<String> regenerateSession() async {
    final newId = _generateNewId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeySessionId, newId);
    _currentSessionId = newId;
    return newId;
  }

  String _generateNewId() {
    return 'sess_${_uuid.v4().replaceAll('-', '').substring(0, 16)}';
  }
}
