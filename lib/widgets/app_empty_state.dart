import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Specially designed empty state with icon badge, title, explanation, and action CTA.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = LucideIcons.inbox,
    this.actionText,
    this.onActionPressed,
    this.actionLeadingIcon,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final IconData? actionLeadingIcon;

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
            // Icon container with soft tint and subtle border
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceSecondary,
                borderRadius: AppRadius.borderR16,
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: Icon(
                icon,
                size: 26,
                color: colors.textSecondary,
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
                description,
                style: AppTextStyles.bodyMedium(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            if (actionText != null && onActionPressed != null) ...[
              AppSpacing.vGap24,
              AppButton(
                text: actionText!,
                onPressed: onActionPressed,
                leadingIcon: actionLeadingIcon,
                size: AppButtonSize.md,
                variant: AppButtonVariant.primary,
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
