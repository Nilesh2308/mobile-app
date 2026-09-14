import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Premium frosted-glass top bar with gradient accent line.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBackTap,
    this.bottom,
    this.height = 56.0,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final PreferredSizeWidget? bottom;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(
        height + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isDark ? 24 : 16,
          sigmaY: isDark ? 24 : 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? colors.background.withValues(alpha: 0.7)
                : colors.background.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? colors.primary.withValues(alpha: 0.15)
                    : colors.borderSubtle,
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: height - 1.0,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
                  child: Row(
                    children: [
                      if (showBackButton) ...[
                        GestureDetector(
                          onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : colors.surfaceSecondary,
                              borderRadius: AppRadius.borderR8,
                              border: Border.all(
                                color: isDark ? colors.glassBorder : colors.borderSubtle,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.arrowLeft,
                              size: 16,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        AppSpacing.hGap8,
                      ] else if (leading != null) ...[
                        leading!,
                        AppSpacing.hGap8,
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: AppTextStyles.headingSmall(color: colors.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (subtitle != null) ...[
                              AppSpacing.vGap2,
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  subtitle!,
                                  style: AppTextStyles.caption(color: colors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (actions != null) ...[
                        AppSpacing.hGap6,
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!,
                        ),
                      ],
                    ],
                  ),
                ),
                ?bottom,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
