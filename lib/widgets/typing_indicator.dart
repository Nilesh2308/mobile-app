import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Custom SaaS "Thinking" indicator with bot avatar and staggered animated pulsing dots.
/// Replaces generic CircularProgressIndicator in conversational UI.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    super.key,
    this.message = 'Searching documents...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bot Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: AppRadius.borderR8,
              border: Border.all(color: colors.primary.withValues(alpha: 0.25), width: 1),
            ),
            child: Icon(
              LucideIcons.bot,
              size: 16,
              color: colors.primary,
            ),
          ),
          AppSpacing.hGap12,

          // Pulsing Dots Bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.borderR12,
              border: Border.all(color: colors.borderSubtle, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(colors.primary, 0.ms),
                AppSpacing.hGap4,
                _buildDot(colors.primary, 180.ms),
                AppSpacing.hGap4,
                _buildDot(colors.primary, 360.ms),
                AppSpacing.hGap8,
                Text(
                  message,
                  style: AppTextStyles.caption(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 150.ms)
        .slideY(begin: 0.1, end: 0, duration: 150.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildDot(Color color, Duration delay) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.3, 1.3),
          duration: 600.ms,
          delay: delay,
          curve: Curves.easeInOut,
        )
        .fade(
          begin: 0.35,
          end: 1.0,
          duration: 600.ms,
          delay: delay,
          curve: Curves.easeInOut,
        );
  }
}
