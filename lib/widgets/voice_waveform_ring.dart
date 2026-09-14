import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum VoiceRingState {
  idle,
  listening,
  transcribing,
  thinking,
  speaking,
}

/// Premium animated voice orb with concentric neon rings, pulsing glow,
/// and circular audio bars. The centerpiece of the Voice Assistant screen.
class VoiceWaveformRing extends StatefulWidget {
  const VoiceWaveformRing({
    super.key,
    required this.state,
    required this.child,
    this.diameter = 100.0,
  });

  final VoiceRingState state;
  final Widget child;
  final double diameter;

  @override
  State<VoiceWaveformRing> createState() => _VoiceWaveformRingState();
}

class _VoiceWaveformRingState extends State<VoiceWaveformRing>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  late final AnimationController _barsController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _barsController.dispose();
    super.dispose();
  }

  List<Color> _getStateGradient() {
    switch (widget.state) {
      case VoiceRingState.listening:
        return AppColors.voiceListeningGradient;
      case VoiceRingState.transcribing:
        return AppColors.voiceTranscribingGradient;
      case VoiceRingState.thinking:
        return AppColors.voiceThinkingGradient;
      case VoiceRingState.speaking:
        return AppColors.voiceSpeakingGradient;
      case VoiceRingState.idle:
        return AppColors.voiceIdleGradient;
    }
  }

  Color _getStatePrimaryColor() {
    switch (widget.state) {
      case VoiceRingState.listening:
        return AppColors.neonMagenta;
      case VoiceRingState.transcribing:
        return AppColors.neonOrange;
      case VoiceRingState.thinking:
        return AppColors.neonCyan;
      case VoiceRingState.speaking:
        return AppColors.neonGreen;
      case VoiceRingState.idle:
        return AppColors.neonPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = widget.state != VoiceRingState.idle;
    final gradient = _getStateGradient();
    final primaryColor = _getStatePrimaryColor();
    final totalSize = widget.diameter * 2.15;

    return Center(
      child: SizedBox(
        width: totalSize,
        height: totalSize,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _rotateController, _barsController]),
          builder: (context, child) {
            final pulse = _pulseController.value;
            final rotation = _rotateController.value;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Layer 1: Outermost soft glow aura
                if (isBusy)
                  Transform.scale(
                    scale: 0.9 + 0.2 * pulse,
                    child: Container(
                      width: totalSize,
                      height: totalSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.12 * (0.5 + 0.5 * pulse)),
                            primaryColor.withValues(alpha: 0.04 * pulse),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                // Layer 2: Circular audio bars (rotate slowly when active)
                if (isBusy)
                  Transform.rotate(
                    angle: rotation * 2 * pi,
                    child: CustomPaint(
                      size: Size(widget.diameter * 1.9, widget.diameter * 1.9),
                      painter: _CircularAudioBarsPainter(
                        progress: _barsController.value,
                        barCount: 36,
                        barWidth: 2.5,
                        maxBarHeight: widget.diameter * 0.22,
                        minBarHeight: 3.0,
                        gradientColors: gradient,
                        isActive: true,
                      ),
                    ),
                  ),

                // Layer 3: Outer ring with gradient border
                if (isBusy)
                  Transform.scale(
                    scale: 0.95 + 0.08 * pulse,
                    child: Container(
                      width: widget.diameter * 1.45,
                      height: widget.diameter * 1.45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3 + 0.2 * pulse),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                // Layer 4: Middle ring (pulsing)
                if (isBusy)
                  Transform.scale(
                    scale: 0.98 + 0.05 * (1 - pulse),
                    child: Container(
                      width: widget.diameter * 1.22,
                      height: widget.diameter * 1.22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2 + 0.15 * pulse),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),

                // Layer 5: Idle state — subtle breathing ring
                if (!isBusy) ...[
                  Transform.scale(
                    scale: 0.95 + 0.05 * pulse,
                    child: Container(
                      width: widget.diameter * 1.35,
                      height: widget.diameter * 1.35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.1 + 0.08 * pulse),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                  // Idle subtle glow
                  Container(
                    width: widget.diameter * 1.2,
                    height: widget.diameter * 1.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],

                // Layer 6: The main button (child)
                child!,
              ],
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Paints circular audio bars arranged around a center point
class _CircularAudioBarsPainter extends CustomPainter {
  _CircularAudioBarsPainter({
    required this.progress,
    required this.barCount,
    required this.barWidth,
    required this.maxBarHeight,
    required this.minBarHeight,
    required this.gradientColors,
    required this.isActive,
  });

  final double progress;
  final int barCount;
  final double barWidth;
  final double maxBarHeight;
  final double minBarHeight;
  final List<Color> gradientColors;
  final bool isActive;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - maxBarHeight;
    final angleStep = (2 * pi) / barCount;

    for (int i = 0; i < barCount; i++) {
      final angle = i * angleStep - pi / 2;

      // Multi-frequency sine wave for organic feel
      final wave1 = sin(progress * 2 * pi * 2 + i * 0.45);
      final wave2 = sin(progress * 2 * pi * 3.2 + i * 0.7) * 0.4;
      final wave3 = cos(progress * 2 * pi * 1.5 + i * 0.35) * 0.25;
      final combinedWave = (wave1 + wave2 + wave3) / 1.65;

      final normalizedHeight = isActive
          ? (combinedWave + 1) / 2
          : 0.15 + 0.08 * sin(progress * 2 * pi * 0.4 + i * 0.5);

      final barHeight = minBarHeight + (maxBarHeight - minBarHeight) * normalizedHeight;

      final startX = center.dx + baseRadius * cos(angle);
      final startY = center.dy + baseRadius * sin(angle);
      final endX = center.dx + (baseRadius + barHeight) * cos(angle);
      final endY = center.dy + (baseRadius + barHeight) * sin(angle);

      final opacity = isActive ? 0.4 + 0.6 * normalizedHeight : 0.15;

      final barColor = gradientColors.isNotEmpty
          ? Color.lerp(gradientColors.first, gradientColors.last, i / barCount)!
          : const Color(0xFF6366F1);

      final paint = Paint()
        ..color = barColor.withValues(alpha: opacity)
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularAudioBarsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isActive != isActive;
  }
}
