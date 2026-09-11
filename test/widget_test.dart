import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_ai/main.dart';
import 'package:voice_ai/models/chat_message.dart';
import 'package:voice_ai/providers/session_provider.dart';
import 'package:voice_ai/providers/theme_provider.dart';
import 'package:voice_ai/screens/chat_screen.dart';
import 'package:voice_ai/screens/knowledge_base_screen.dart';
import 'package:voice_ai/screens/settings_modal.dart';
import 'package:voice_ai/screens/voice_screen.dart';
import 'package:voice_ai/services/session_service.dart';
import 'package:voice_ai/theme/theme.dart';
import 'package:voice_ai/widgets/widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'voiceai_persistent_session_id': 'sess_test_12345678',
      'voiceai_theme_mode': 'dark',
    });
  });

  testWidgets('App renders custom SaaS bottom navigation shell with 3 tabs', (WidgetTester tester) async {
    final sessionService = SessionService();
    await sessionService.init();

    final themeProvider = ThemeProvider();
    await themeProvider.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SessionProvider>(
            create: (_) => SessionProvider(sessionService: sessionService),
          ),
        ],
        child: const VoiceAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 3 navigation tabs are visible
    expect(find.text('Knowledge Base'), findsWidgets);
    expect(find.text('Chat'), findsWidgets);
    expect(find.text('Voice Assistant'), findsWidgets);

    // Switch to Knowledge Base tab
    await tester.tap(find.text('Knowledge Base').last);
    await tester.pumpAndSettle();
    expect(find.text('Tap to upload documents'), findsOneWidget);

    // Switch to Voice Assistant tab
    await tester.tap(find.text('Voice Assistant').last);
    await tester.pumpAndSettle();
    expect(find.text('Tap microphone to speak'), findsOneWidget);
  });

  testWidgets('Knowledge Base screen renders clean upload card and document list', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: KnowledgeBaseScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify prominent upload area card
    expect(find.text('Tap to upload documents'), findsOneWidget);
    expect(find.text('Supports multi-select .pdf, .docx, and .txt files'), findsOneWidget);

    // Verify format tags
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('DOCX'), findsOneWidget);
    expect(find.text('TXT'), findsOneWidget);

    // Verify document cards render
    expect(find.text('Indexed Documents'), findsOneWidget);
    expect(find.text('acme_hr_policy_handbook.txt'), findsOneWidget);
    expect(find.text('travel_and_expense_policy_2026.pdf'), findsOneWidget);
  });

  testWidgets('Theme toggle switches between light and dark modes', (WidgetTester tester) async {
    final sessionService = SessionService();
    await sessionService.init();

    final themeProvider = ThemeProvider();
    await themeProvider.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SessionProvider>(
            create: (_) => SessionProvider(sessionService: sessionService),
          ),
        ],
        child: const VoiceAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dark mode toggle icon
    expect(find.byIcon(LucideIcons.sun), findsOneWidget);

    // Tap toggle
    await tester.tap(find.byIcon(LucideIcons.sun));
    await tester.pumpAndSettle();

    // Now in light mode
    expect(find.byIcon(LucideIcons.moon), findsOneWidget);
  });

  testWidgets('ChatBubble correctly renders user and all 3 bot response states', (WidgetTester tester) async {
    // 1. User message
    final userMsg = ChatMessage(
      id: '1',
      text: 'Hello, what is our policy?',
      isUser: true,
      timestamp: DateTime.now(),
    );

    // 2. Knowledge Base response with citations
    final kbMsg = ChatMessage(
      id: '2',
      text: 'According to company policy, the remote allowance is **\$500**.',
      isUser: false,
      timestamp: DateTime.now(),
      source: 'knowledge_base',
      citations: [
        const Citation(
          filename: 'acme_policy.pdf',
          chunkText: 'Eligible employees may expense up to \$500 for home office setup.',
          score: 0.92,
        ),
      ],
    );

    // 3. LLM General response
    final generalMsg = ChatMessage(
      id: '3',
      text: 'Ergonomic chairs should provide lumbar support.',
      isUser: false,
      timestamp: DateTime.now(),
      source: 'llm_general',
    );

    // 4. Refused response
    final refusedMsg = ChatMessage(
      id: '4',
      text: 'I can only assist with verified company policies and professional documentation.',
      isUser: false,
      timestamp: DateTime.now(),
      source: 'refused',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ChatBubble(message: userMsg),
                ChatBubble(message: kbMsg),
                ChatBubble(message: generalMsg),
                ChatBubble(message: refusedMsg),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify user bubble
    expect(find.text('Hello, what is our policy?'), findsOneWidget);

    // Verify Knowledge Base badge and content
    expect(find.text('From your documents'), findsOneWidget);
    expect(find.text('1 Verified Citation'), findsOneWidget);

    // Test expanding citations accordion
    await tester.tap(find.text('1 Verified Citation'));
    await tester.pumpAndSettle();
    expect(find.text('acme_policy.pdf'), findsOneWidget);
    expect(find.text('Score: 0.920'), findsOneWidget);
    expect(find.text('Eligible employees may expense up to \$500 for home office setup.'), findsOneWidget);

    // Verify General Knowledge badge
    expect(find.text('General knowledge'), findsOneWidget);

    // Verify Refused message badge and pill
    expect(find.text('Query Refused'), findsOneWidget);
    expect(find.text('I can only assist with verified company policies and professional documentation.'), findsOneWidget);
  });

  testWidgets('TypingIndicator renders animated pulsing dots with avatar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: TypingIndicator(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify TypingIndicator elements
    expect(find.byIcon(LucideIcons.bot), findsOneWidget);
    expect(find.text('Searching documents...'), findsOneWidget);
    expect(find.byType(TypingIndicator), findsOneWidget);
  });

  testWidgets('ChatScreen renders clean empty state and input field', (WidgetTester tester) async {
    final sessionService = SessionService();
    await sessionService.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => SessionProvider(sessionService: sessionService),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: ChatScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify clean welcome empty state
    expect(find.text('How can I help you today?'), findsOneWidget);
    expect(find.text('Ask any question grounded in your uploaded documents. Responses include verifiable citations and domain insights.'), findsOneWidget);

    // Verify chat input field
    expect(find.text('Ask anything about your documents...'), findsOneWidget);
    expect(find.byIcon(LucideIcons.send), findsOneWidget);
  });

  testWidgets('VoiceScreen renders large focal mic button and clean status header', (WidgetTester tester) async {
    final sessionService = SessionService();
    await sessionService.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<SessionProvider>(
        create: (_) => SessionProvider(sessionService: sessionService),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: VoiceScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify large circular mic focal button
    expect(find.byIcon(LucideIcons.mic), findsOneWidget);
    expect(find.text('Tap microphone to speak'), findsOneWidget);

    // Verify clean Voice empty state
    expect(find.text('Voice Assistant Ready'), findsOneWidget);
    expect(find.text('Tap the microphone above to speak your question aloud.'), findsOneWidget);
  });

  testWidgets('PermissionDeniedCard displays clear explanation and Open App Settings action', (WidgetTester tester) async {
    bool requested = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: PermissionDeniedCard(
            onRequestPermission: () => requested = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Microphone Permission Required'), findsOneWidget);
    expect(find.text('Open App Settings'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    expect(requested, isTrue);
  });

  testWidgets('ChatBubble renders Replay Spoken Audio button when audioBase64 is provided', (WidgetTester tester) async {
    bool playTriggered = false;

    final botMsgWithAudio = ChatMessage(
      id: 'voice_bot_1',
      text: 'Here is your spoken policy answer.',
      isUser: false,
      timestamp: DateTime.now(),
      source: 'knowledge_base',
      audioBase64: 'UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA=',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ChatBubble(
            message: botMsgWithAudio,
            onPlayAudio: () => playTriggered = true,
            isAudioPlaying: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Replay Spoken Audio'), findsOneWidget);
    expect(find.byIcon(LucideIcons.volume2), findsOneWidget);

    await tester.tap(find.text('Replay Spoken Audio'));
    expect(playTriggered, isTrue);
  });

  testWidgets('SettingsModal renders Session Stats card and backend restart note', (WidgetTester tester) async {
    final sessionService = SessionService();
    await sessionService.init();

    final themeProvider = ThemeProvider();
    await themeProvider.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SessionProvider>(
            create: (_) => SessionProvider(sessionService: sessionService),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SettingsModal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Session Stats card
    expect(find.text('Session Stats'), findsOneWidget);
    expect(find.text('Total Queries Processed'), findsOneWidget);
    expect(find.text('From Documents'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Refused'), findsOneWidget);

    // Verify backend restart transparency note
    expect(
      find.text('Conversation history resets when the backend restarts (no database yet).'),
      findsOneWidget,
    );
  });
}


