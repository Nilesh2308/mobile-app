import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';
import 'providers/session_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_shell.dart';
import 'services/session_service.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize runtime config and session persistence
  await AppConfig.init();
  final sessionService = SessionService();
  await sessionService.init();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
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
}

class VoiceAiApp extends StatelessWidget {
  const VoiceAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'VoiceAI Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.themeMode,
      home: const MainShell(),
    );
  }
}
