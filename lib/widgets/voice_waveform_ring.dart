import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';

enum VoiceRingState {
  idle,
  listening,
  transcribing,
  thinking,
  speaking,
}

/// Dynamic concentric pulsing rings widget surrounding the Voice Assistant mic button.
/// Creates a premium SaaS Edge AI visual aura during recording and playback.
class VoiceWaveformRing extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    Color ringColor;
    switch (state) {
      case VoiceRingState.listening:
        ringColor = colors.error;
        break;
      case VoiceRingState.transcribing:
        ringColor = colors.warning;
        break;
      case VoiceRingState.thinking:
        ringColor = colors.primary;
        break;
      case VoiceRingState.speaking:
        ringColor = colors.success;
        break;
      case VoiceRingState.idle:
        ringColor = colors.primary;
        break;
    }

    final isBusy = state != VoiceRingState.idle;

    return Center(
      child: SizedBox(
        width: diameter * 2.2,
        height: diameter * 2.2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ring 3 (Widest pulse)
            if (isBusy)
              Container(
                width: diameter * 1.95,
                height: diameter * 1.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringColor.withValues(alpha: 0.08),
                  border: Border.all(
                    color: ringColor.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.16, 1.16),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  )
                  .fade(
                    begin: 0.3,
                    end: 0.9,
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),

            // Middle Ring 2
            if (isBusy)
              Container(
                width: diameter * 1.5,
                height: diameter * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringColor.withValues(alpha: 0.14),
                  border: Border.all(
                    color: ringColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.12, 1.12),
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                  )
                  .fade(
                    begin: 0.4,
                    end: 1.0,
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                  ),

            // Subtle Idle Glow when not recording
            if (!isBusy)
              Container(
                width: diameter * 1.25,
                height: diameter * 1.25,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.06),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
              ),

            // Focal Mic Button Child
            child,
          ],
        ),
      ),
    );
  }
}
