import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppBadgeVariant {
  brand,
  success,
  warning,
  error,
  neutral,
}

/// Clean SaaS status badge pill with optional dot indicator.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.showDot = true,
    this.icon,
  });

  final String label;
  final AppBadgeVariant variant;
  final bool showDot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);

    Color bg;
    Color fg;
    Color border;
    Color dot;

    switch (variant) {
      case AppBadgeVariant.brand:
        bg = colors.primaryContainer;
        fg = colors.primary;
        border = colors.primary.withValues(alpha: 0.25);
        dot = colors.primary;
        break;
      case AppBadgeVariant.success:
        bg = colors.successContainer;
        fg = colors.success;
        border = colors.success.withValues(alpha: 0.25);
        dot = colors.success;
        break;
      case AppBadgeVariant.warning:
        bg = colors.warningContainer;
        fg = colors.warning;
        border = colors.warning.withValues(alpha: 0.25);
        dot = colors.warning;
        break;
      case AppBadgeVariant.error:
        bg = colors.errorContainer;
        fg = colors.error;
        border = colors.error.withValues(alpha: 0.25);
        dot = colors.error;
        break;
      case AppBadgeVariant.neutral:
        bg = colors.surfaceSecondary;
        fg = colors.textSecondary;
        border = colors.borderSubtle;
        dot = colors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderRFull,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.hGap4,
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            AppSpacing.hGap4,
          ],
          Text(
            label,
            style: AppTextStyles.label(color: fg, letterSpacing: 0.2).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
