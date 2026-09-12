import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Animated gradient mesh background providing organic, alive-feeling depth.
/// Uses multiple overlapping radial gradients that slowly drift and breathe.
class AnimatedGradientBg extends StatefulWidget {
  const AnimatedGradientBg({
    super.key,
    required this.child,
    this.intensity = 1.0,
    this.accentColors,
  });

  final Widget child;

  /// 0.0 = no animation, 1.0 = full intensity
  final double intensity;

  /// Optional override colors for state-reactive backgrounds
  final List<Color>? accentColors;

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _secondaryController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _secondaryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _secondaryController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _MeshGradientPainter(
            progress: _controller.value,
            secondaryProgress: _secondaryController.value,
            baseColors: widget.accentColors ?? colors.meshColors,
            accentColor: colors.primary,
            intensity: widget.intensity,
            isDark: isDark,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter({
    required this.progress,
    required this.secondaryProgress,
    required this.baseColors,
    required this.accentColor,
    required this.intensity,
    required this.isDark,
  });

  final double progress;
  final double secondaryProgress;
  final List<Color> baseColors;
  final Color accentColor;
  final double intensity;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Base fill
    final bgColor = isDark ? const Color(0xFF050510) : const Color(0xFFF8F9FF);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = bgColor,
    );

    if (intensity <= 0) return;

    // Animated gradient orbs
    final orbs = [
      _GradientOrb(
        centerFraction: Offset(
          0.25 + 0.15 * sin(progress * 2 * pi),
          0.2 + 0.1 * cos(progress * 2 * pi * 0.7),
        ),
        radius: size.width * 0.6,
        color: baseColors.isNotEmpty
            ? baseColors[0].withValues(alpha: 0.3 * intensity)
            : accentColor.withValues(alpha: 0.15 * intensity),
      ),
      _GradientOrb(
        centerFraction: Offset(
          0.75 + 0.12 * cos(secondaryProgress * 2 * pi),
          0.35 + 0.15 * sin(secondaryProgress * 2 * pi * 0.6),
        ),
        radius: size.width * 0.55,
        color: baseColors.length > 1
            ? baseColors[1].withValues(alpha: 0.25 * intensity)
            : accentColor.withValues(alpha: 0.12 * intensity),
      ),
      _GradientOrb(
        centerFraction: Offset(
          0.5 + 0.2 * sin(progress * 2 * pi * 1.3),
          0.75 + 0.1 * cos(secondaryProgress * 2 * pi),
        ),
        radius: size.width * 0.5,
        color: baseColors.length > 2
            ? baseColors[2].withValues(alpha: 0.2 * intensity)
            : accentColor.withValues(alpha: 0.1 * intensity),
      ),
      // Accent orb (primary brand color, very subtle)
      _GradientOrb(
        centerFraction: Offset(
          0.6 + 0.15 * cos(progress * 2 * pi * 0.5),
          0.5 + 0.15 * sin(secondaryProgress * 2 * pi * 0.8),
        ),
        radius: size.width * 0.4,
        color: accentColor.withValues(alpha: (isDark ? 0.08 : 0.05) * intensity),
      ),
    ];

    for (final orb in orbs) {
      final center = Offset(
        orb.centerFraction.dx * size.width,
        orb.centerFraction.dy * size.height,
      );
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [orb.color, orb.color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: orb.radius));
      canvas.drawCircle(center, orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.secondaryProgress != secondaryProgress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.isDark != isDark;
  }
}

class _GradientOrb {
  const _GradientOrb({
    required this.centerFraction,
    required this.radius,
    required this.color,
  });

  final Offset centerFraction;
  final double radius;
  final Color color;
}
