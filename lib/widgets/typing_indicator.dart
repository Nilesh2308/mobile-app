import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Premium "Thinking" indicator with shimmer sweep effect, animated bot avatar,
/// and pulsing gradient dots.
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
          // Bot Avatar with spinning ring effect
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.auroraViolet, AppColors.primary500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.borderR10,
              boxShadow: AppShadows.neonGlow(
                AppColors.auroraViolet,
                intensity: 0.15,
                blur: 8,
              ),
            ),
            child: const Icon(
              LucideIcons.bot,
              size: 16,
              color: Colors.white,
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1500.ms,
                color: Colors.white.withValues(alpha: 0.3),
              ),
          AppSpacing.hGap12,

          // Shimmer-sweep thinking bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s14, vertical: AppSpacing.s10),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: AppRadius.borderR12,
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated pulsing gradient dots
                _buildDot(colors.primary, 0.ms),
                AppSpacing.hGap4,
                _buildDot(AppColors.auroraViolet, 200.ms),
                AppSpacing.hGap4,
                _buildDot(AppColors.neonCyan, 400.ms),
                AppSpacing.hGap10,
                Text(
                  message,
                  style: AppTextStyles.caption(color: colors.textSecondary),
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 2000.ms,
                color: colors.primary.withValues(alpha: 0.08),
              ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.1, end: 0, duration: 200.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildDot(Color color, Duration delay) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.3, 1.3),
          duration: 600.ms,
          delay: delay,
          curve: Curves.easeInOut,
        )
        .fade(
          begin: 0.3,
          end: 1.0,
          duration: 600.ms,
          delay: delay,
          curve: Curves.easeInOut,
        );
  }
}
