import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Button visual styles
enum AppButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
}

/// Button sizes
enum AppButtonSize {
  sm,
  md,
  lg,
}

/// Premium SaaS button with gradient fill, neon glow, shimmer effects,
/// and micro-interaction press feedback.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isDisabled;
  final bool isFullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  bool get _effectiveDisabled => widget.isDisabled || widget.isLoading || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dimensions by size
    final double height;
    final EdgeInsets padding;
    final double iconSize;
    final TextStyle textStyle;

    switch (widget.size) {
      case AppButtonSize.sm:
        height = 32.0;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.s12);
        iconSize = 14.0;
        textStyle = AppTextStyles.label(letterSpacing: 0.1).copyWith(fontSize: 12);
        break;
      case AppButtonSize.md:
        height = 40.0;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.s16);
        iconSize = 16.0;
        textStyle = AppTextStyles.label(letterSpacing: 0.1).copyWith(fontSize: 13);
        break;
      case AppButtonSize.lg:
        height = 48.0;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.s20);
        iconSize = 18.0;
        textStyle = AppTextStyles.label(letterSpacing: 0.1).copyWith(fontSize: 14);
        break;
    }

    // Colors and borders by variant
    Color backgroundColor;
    Color foregroundColor;
    Border? border;
    List<BoxShadow>? shadows;
    Gradient? gradient;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = colors.primary;
        foregroundColor = Colors.white;
        border = null;
        gradient = const LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        if (!_effectiveDisabled) {
          shadows = AppShadows.neonGlow(
            colors.primary,
            intensity: 0.25,
            blur: 12,
          );
        }
        break;
      case AppButtonVariant.secondary:
        backgroundColor = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : colors.surfaceSecondary;
        foregroundColor = colors.textPrimary;
        border = Border.all(
          color: isDark ? colors.glassBorder : colors.borderSubtle,
          width: 1,
        );
        gradient = null;
        break;
      case AppButtonVariant.outline:
        backgroundColor = AppColors.transparent;
        foregroundColor = colors.textPrimary;
        border = Border.all(color: colors.borderStrong, width: 1);
        gradient = null;
        break;
      case AppButtonVariant.ghost:
        backgroundColor = _isPressed
            ? (isDark ? Colors.white.withValues(alpha: 0.06) : colors.surfaceSecondary)
            : AppColors.transparent;
        foregroundColor = colors.textPrimary;
        border = null;
        gradient = null;
        break;
      case AppButtonVariant.destructive:
        backgroundColor = colors.errorContainer;
        foregroundColor = colors.error;
        border = Border.all(color: colors.error.withValues(alpha: 0.3), width: 1);
        gradient = null;
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          AppSpacing.hGap8,
        ] else if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: iconSize, color: foregroundColor),
          AppSpacing.hGap8,
        ],
        Text(
          widget.text,
          style: textStyle.copyWith(color: foregroundColor),
        ),
        if (!widget.isLoading && widget.trailingIcon != null) ...[
          AppSpacing.hGap8,
          Icon(widget.trailingIcon, size: iconSize, color: foregroundColor),
        ],
      ],
    );

    Widget button = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: AppRadius.borderR12,
        border: border,
        boxShadow: shadows,
      ),
      child: content,
    );

    // Add shimmer to primary buttons
    if (widget.variant == AppButtonVariant.primary && !_effectiveDisabled) {
      button = button
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 3000.ms,
            color: Colors.white.withValues(alpha: 0.1),
            delay: 1000.ms,
          );
    }

    return AnimatedScale(
      scale: _isPressed && !_effectiveDisabled ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _effectiveDisabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTapDown: _effectiveDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: _effectiveDisabled
              ? null
              : (_) {
                  setState(() => _isPressed = false);
                  widget.onPressed?.call();
                },
          onTapCancel: _effectiveDisabled ? null : () => setState(() => _isPressed = false),
          child: button,
        ),
      ),
    );
  }
}
