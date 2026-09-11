import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Designed loading state with contextual message and micro-animations.
/// Never displays a bare unstyled CircularProgressIndicator.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.message = 'Loading...',
    this.subMessage,
  });

  final String message;
  final String? subMessage;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24, vertical: AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Styled indicator container
            Container(
              width: 52,
              height: 52,
              padding: AppSpacing.p12,
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: AppRadius.borderR16,
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
            ),
            AppSpacing.vGap16,
            Text(
              message,
              style: AppTextStyles.bodyMedium(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              AppSpacing.vGap6,
              Text(
                subMessage!,
                style: AppTextStyles.caption(color: colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 200.ms, curve: Curves.easeOut),
      ),
    );
  }
}

/// Shimmer skeleton block for placeholder loading
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.borderR6,
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: borderRadius,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.5, end: 1.0, duration: 800.ms, curve: Curves.easeInOut);
  }
}
