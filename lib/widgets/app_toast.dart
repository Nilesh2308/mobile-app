import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppToastVariant {
  success,
  error,
  info,
}

/// Custom styled toast notification adhering to the SaaS design system.
/// Never looks like a default Material SnackBar.
abstract final class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppToastVariant variant = AppToastVariant.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color border;
    Color iconColor;
    IconData icon;

    switch (variant) {
      case AppToastVariant.success:
        bg = colors.surface;
        border = colors.success.withValues(alpha: 0.35);
        iconColor = colors.success;
        icon = LucideIcons.checkCircle2;
        break;
      case AppToastVariant.error:
        bg = colors.surface;
        border = colors.error.withValues(alpha: 0.35);
        iconColor = colors.error;
        icon = LucideIcons.alertTriangle;
        break;
      case AppToastVariant.info:
        bg = colors.surface;
        border = colors.primary.withValues(alpha: 0.35);
        iconColor = colors.primary;
        icon = LucideIcons.info;
        break;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
        duration: duration,
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.borderR12,
            border: Border.all(color: border, width: 1.0),
            boxShadow: AppShadows.card(isDark),
          ),
          child: Row(
            children: [
              Container(
                padding: AppSpacing.p6,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderR8,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              AppSpacing.hGap12,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title,
                        style: AppTextStyles.label(color: colors.textPrimary),
                      ),
                      AppSpacing.vGap2,
                    ],
                    Text(
                      message,
                      style: AppTextStyles.bodySmall(color: colors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .slideY(begin: 0.2, end: 0, duration: 200.ms, curve: Curves.easeOutCubic)
            .fadeIn(duration: 180.ms),
      ),
    );
  }
}
