import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Premium glassmorphism SaaS card with frosted blur, gradient border option,
/// soft shadows, and press feedback.
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
    this.useGlass = false,
    this.glassBlur = 16.0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool hasShadow;

  /// Enable glassmorphism effect with backdrop blur
  final bool useGlass;
  final double glassBlur;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = widget.backgroundColor ??
        (widget.useGlass
            ? (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.7))
            : colors.surface);
    final borderCol = widget.borderColor ??
        (widget.useGlass ? colors.glassBorder : colors.borderSubtle);

    Widget card = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: widget.borderRadius,
        border: Border.all(color: borderCol, width: widget.borderWidth),
        boxShadow: widget.hasShadow ? AppShadows.card(isDark) : null,
      ),
      child: widget.child,
    );

    // Wrap with BackdropFilter for glassmorphism
    if (widget.useGlass) {
      card = ClipRRect(
        borderRadius: widget.borderRadius.resolve(TextDirection.ltr),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.glassBlur,
            sigmaY: widget.glassBlur,
          ),
          child: card,
        ),
      );
    }

    return AnimatedScale(
      scale: _isPressed && widget.onTap != null ? 0.98 : 1.0,
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
        child: card,
      ),
    );
  }
}
