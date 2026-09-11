import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// SaaS Top Bar replacing default Material AppBar with sleek, safe-area aware navigation.
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

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Row(
                children: [
                  if (showBackButton) ...[
                    GestureDetector(
                      onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colors.surfaceSecondary,
                          borderRadius: AppRadius.borderR8,
                          border: Border.all(color: colors.borderSubtle, width: 1),
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          size: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    AppSpacing.hGap12,
                  ] else if (leading != null) ...[
                    leading!,
                    AppSpacing.hGap12,
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.headingSmall(color: colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          AppSpacing.vGap2,
                          Text(
                            subtitle!,
                            style: AppTextStyles.caption(color: colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null) ...[
                    AppSpacing.hGap8,
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
    );
  }
}
