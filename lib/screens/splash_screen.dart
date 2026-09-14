import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_shell.dart';

/// Welcome / Launch Poster Screen displayed when the mobile app opens.
/// Displays the custom creator & app poster with seamless edge integration,
/// exact 4-second hold, and the original "Loading your workspace..." loader
/// animating from 0% to 100% before smoothly transitioning into the main app.
class SplashScreen extends StatefulWidget {
  final Duration displayDuration;
  final Widget nextScreen;

  const SplashScreen({
    super.key,
    this.displayDuration = const Duration(seconds: 4),
    this.nextScreen = const MainShell(),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _curvedProgress;
  Timer? _navigationTimer;
  bool _hasNavigated = false;

  static const String _posterAsset = 'assets/branding/welcome_poster.png';

  @override
  void initState() {
    super.initState();

    // 4-second progress animation from 0.0 to 1.0
    _progressController = AnimationController(
      vsync: this,
      duration: widget.displayDuration,
    );

    _curvedProgress = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.forward();

    // Automatic navigation after full duration
    _navigationTimer = Timer(widget.displayDuration, () {
      _navigateToMain();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the poster image to ensure instant rendering without blank flashes
    precacheImage(const AssetImage(_posterAsset), context);
  }

  void _navigateToMain() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navigationTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exact edge gradient matching the poster top (#D6DDFD) and bottom (#F8FAFE)
    const topBgColor = Color(0xFFD6DDFD);
    const midBgColor = Color(0xFFE8EEFC);
    const bottomBgColor = Color(0xFFF8FAFE);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: bottomBgColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topBgColor, midBgColor, bottomBgColor],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              // Constrain max width for tablets, foldables, and desktop while filling phones perfectly
              constraints: const BoxConstraints(maxWidth: 520),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full poster image rendered with high-fidelity fitting
                  Positioned.fill(
                    child: Image.asset(
                      _posterAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  // Original "Loading your workspace..." loader anchored at the bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: AnimatedBuilder(
                          animation: _curvedProgress,
                          builder: (context, child) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Rounded pill capsule track
                                Container(
                                  width: 195,
                                  height: 6.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDFE3EC),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: _curvedProgress.value.clamp(0.0, 1.0),
                                      child: Container(
                                        height: 6.5,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF5A67D8),
                                              Color(0xFF6C63FF),
                                              Color(0xFF4F46E5),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(99),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6C63FF)
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 5,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Original Typography
                                const Text(
                                  'Loading your workspace...',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8E95A5),
                                    letterSpacing: 0.25,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
