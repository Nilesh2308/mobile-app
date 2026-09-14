import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_ai/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders poster without skip button and with workspace loader',
      (WidgetTester tester) async {
    const dummyNextScreen = Scaffold(
      body: Center(child: Text('Next Screen')),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          displayDuration: Duration(seconds: 4),
          nextScreen: dummyNextScreen,
        ),
      ),
    );

    // Verify Image asset is present
    expect(find.byType(Image), findsOneWidget);

    // Verify Skip button is NOT present
    expect(find.text('Skip'), findsNothing);

    // Verify original "Loading your workspace..." text is present
    expect(find.text('Loading your workspace...'), findsOneWidget);
  });

  testWidgets('SplashScreen transitions to next screen after 4 second hold completes',
      (WidgetTester tester) async {
    const dummyNextScreen = Scaffold(
      body: Center(child: Text('Main Workspace Screen')),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          displayDuration: Duration(seconds: 4),
          nextScreen: dummyNextScreen,
        ),
      ),
    );

    // Initially on splash screen
    expect(find.text('Loading your workspace...'), findsOneWidget);
    expect(find.text('Main Workspace Screen'), findsNothing);

    // Advance 2 seconds (halfway)
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Loading your workspace...'), findsOneWidget);
    expect(find.text('Main Workspace Screen'), findsNothing);

    // Advance remaining 2 seconds + transition time
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Now transitioned to next screen
    expect(find.text('Main Workspace Screen'), findsOneWidget);
  });
}
