import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Clean SaaS container card with subtle borders, soft shadows, and optional press feedback.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.p16,
    this.onTap,
    this.borderRadius = AppRadius.borderR14,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.hasShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool hasShadow;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = widget.backgroundColor ?? colors.surface;
    final borderCol = widget.borderColor ?? colors.borderSubtle;

    return AnimatedScale(
      scale: _isPressed && widget.onTap != null ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null
            ? (_) {
                setState(() => _isPressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: widget.borderRadius,
            border: Border.all(color: borderCol, width: widget.borderWidth),
            boxShadow: widget.hasShadow ? AppShadows.card(isDark) : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
