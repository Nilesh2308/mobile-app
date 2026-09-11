import 'package:flutter/foundation.dart';
import '../services/session_service.dart';

/// Provider for managing active session ID and conversation continuity.
class SessionProvider extends ChangeNotifier {
  SessionProvider({required this.sessionService});

  final SessionService sessionService;

  String get sessionId => sessionService.sessionId;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    await sessionService.init();

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> resetSession() async {
    await sessionService.regenerateSession();
    notifyListeners();
  }
}
