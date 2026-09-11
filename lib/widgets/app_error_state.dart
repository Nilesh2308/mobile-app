import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Specially designed error state with error badge, message, and retry CTA.
/// Never displays a bare plain Text("Error").
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryText = 'Try again',
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryText;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

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
            // Error icon container with soft red container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: AppRadius.borderR16,
                border: Border.all(color: colors.error.withValues(alpha: 0.3), width: 1),
              ),
              child: Icon(
                LucideIcons.triangleAlert,
                size: 24,
                color: colors.error,
              ),
            ),
            AppSpacing.vGap16,
            Text(
              title,
              style: AppTextStyles.headingSmall(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGap8,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null || onSecondaryAction != null) ...[
              AppSpacing.vGap24,
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onSecondaryAction != null && secondaryActionText != null) ...[
                    AppButton(
                      text: secondaryActionText!,
                      onPressed: onSecondaryAction,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.md,
                    ),
                    AppSpacing.hGap12,
                  ],
                  if (onRetry != null)
                    AppButton(
                      text: retryText,
                      onPressed: onRetry,
                      leadingIcon: LucideIcons.refreshCw,
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.md,
                    ),
                ],
              ),
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 200.ms, curve: Curves.easeOut)
            .slideY(begin: 0.05, end: 0, duration: 200.ms, curve: Curves.easeOut),
      ),
    );
  }
}
