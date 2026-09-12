import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Custom audio visualization bars — sine-wave driven animated bars
/// that react to voice states. Used around the voice orb and in audio playback.
class AnimatedAudioBars extends StatefulWidget {
  const AnimatedAudioBars({
    super.key,
    this.barCount = 24,
    this.barWidth = 3.0,
    this.maxBarHeight = 30.0,
    this.minBarHeight = 4.0,
    this.color,
    this.gradientColors,
    this.isActive = true,
    this.circular = false,
    this.diameter = 120.0,
    this.speed = 1.0,
  });

  final int barCount;
  final double barWidth;
  final double maxBarHeight;
  final double minBarHeight;
  final Color? color;
  final List<Color>? gradientColors;
  final bool isActive;

  /// If true, bars are arranged in a circle (for voice orb)
  final bool circular;
  final double diameter;
  final double speed;

  @override
  State<AnimatedAudioBars> createState() => _AnimatedAudioBarsState();
}

class _AnimatedAudioBarsState extends State<AnimatedAudioBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2000 / widget.speed).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final barColor = widget.color ?? colors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (widget.circular) {
          return CustomPaint(
            size: Size(widget.diameter, widget.diameter),
            painter: _CircularBarsPainter(
              progress: _controller.value,
              barCount: widget.barCount,
              barWidth: widget.barWidth,
              maxBarHeight: widget.maxBarHeight,
              minBarHeight: widget.minBarHeight,
              color: barColor,
              gradientColors: widget.gradientColors,
              isActive: widget.isActive,
            ),
          );
        }

        return CustomPaint(
          size: Size(widget.barCount * (widget.barWidth + 2), widget.maxBarHeight),
          painter: _LinearBarsPainter(
            progress: _controller.value,
            barCount: widget.barCount,
            barWidth: widget.barWidth,
            maxBarHeight: widget.maxBarHeight,
            minBarHeight: widget.minBarHeight,
            color: barColor,
            gradientColors: widget.gradientColors,
            isActive: widget.isActive,
          ),
        );
      },
    );
  }
}

/// Paints circular audio bars arranged around a center point
class _CircularBarsPainter extends CustomPainter {
  _CircularBarsPainter({
    required this.progress,
    required this.barCount,
    required this.barWidth,
    required this.maxBarHeight,
    required this.minBarHeight,
    required this.color,
    this.gradientColors,
    required this.isActive,
  });

  final double progress;
  final int barCount;
  final double barWidth;
  final double maxBarHeight;
  final double minBarHeight;
  final Color color;
  final List<Color>? gradientColors;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - maxBarHeight;
    final angleStep = (2 * pi) / barCount;

    for (int i = 0; i < barCount; i++) {
      final angle = i * angleStep - pi / 2;

      // Multi-frequency sine wave for organic feel
      final wave1 = sin(progress * 2 * pi + i * 0.4);
      final wave2 = sin(progress * 2 * pi * 1.7 + i * 0.6) * 0.5;
      final wave3 = cos(progress * 2 * pi * 0.8 + i * 0.3) * 0.3;
      final combinedWave = (wave1 + wave2 + wave3) / 1.8;

      final normalizedHeight = isActive
          ? (combinedWave + 1) / 2 // 0 to 1
          : 0.15 + 0.1 * sin(progress * 2 * pi * 0.3 + i * 0.5);

      final barHeight = minBarHeight + (maxBarHeight - minBarHeight) * normalizedHeight;

      final startX = center.dx + baseRadius * cos(angle);
      final startY = center.dy + baseRadius * sin(angle);
      final endX = center.dx + (baseRadius + barHeight) * cos(angle);
      final endY = center.dy + (baseRadius + barHeight) * sin(angle);

      final opacity = isActive ? 0.5 + 0.5 * normalizedHeight : 0.2;

      final paint = Paint()
        ..color = (gradientColors != null && gradientColors!.isNotEmpty
                ? Color.lerp(gradientColors!.first, gradientColors!.last, i / barCount)!
                : color)
            .withValues(alpha: opacity)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularBarsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}

/// Paints linear horizontal audio bars (for inline playback visualization)
class _LinearBarsPainter extends CustomPainter {
  _LinearBarsPainter({
    required this.progress,
    required this.barCount,
    required this.barWidth,
    required this.maxBarHeight,
    required this.minBarHeight,
    required this.color,
    this.gradientColors,
    required this.isActive,
  });

  final double progress;
  final int barCount;
  final double barWidth;
  final double maxBarHeight;
  final double minBarHeight;
  final Color color;
  final List<Color>? gradientColors;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = (size.width - barCount * barWidth) / (barCount - 1).clamp(1, 100);

    for (int i = 0; i < barCount; i++) {
      final wave = sin(progress * 2 * pi + i * 0.5);
      final wave2 = cos(progress * 2 * pi * 1.4 + i * 0.3) * 0.4;
      final combinedWave = (wave + wave2) / 1.4;

      final normalizedHeight = isActive
          ? (combinedWave + 1) / 2
          : 0.2 + 0.1 * sin(progress * 2 * pi * 0.3 + i * 0.4);

      final barHeight = minBarHeight + (maxBarHeight - minBarHeight) * normalizedHeight;
      final x = i * (barWidth + spacing);
      final y = (size.height - barHeight) / 2;

      final opacity = isActive ? 0.5 + 0.5 * normalizedHeight : 0.25;

      final paint = Paint()
        ..color = (gradientColors != null && gradientColors!.isNotEmpty
                ? Color.lerp(gradientColors!.first, gradientColors!.last, i / barCount)!
                : color)
            .withValues(alpha: opacity)
        ..strokeCap = StrokeCap.round;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinearBarsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}
