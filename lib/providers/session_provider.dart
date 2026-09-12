import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/session_service.dart';

/// Provider for managing active session ID, conversation continuity,
/// and message state across Chat and Voice Assistant screens.
class SessionProvider extends ChangeNotifier {
  SessionProvider({required this.sessionService});

  final SessionService sessionService;

  String get sessionId => sessionService.sessionId;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  final List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  final List<ChatMessage> _voiceMessages = [];
  List<ChatMessage> get voiceMessages => List.unmodifiable(_voiceMessages);

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    await sessionService.init();

    _isInitializing = false;
    notifyListeners();
  }

  void addChatMessage(ChatMessage message) {
    _chatMessages.add(message);
    notifyListeners();
  }

  void addVoiceMessage(ChatMessage message) {
    _voiceMessages.add(message);
    notifyListeners();
  }

  Future<void> resetSession() async {
    await sessionService.regenerateSession();
    _chatMessages.clear();
    _voiceMessages.clear();
    notifyListeners();
  }

  void clearAllMessages() {
    _chatMessages.clear();
    _voiceMessages.clear();
    notifyListeners();
  }
}
