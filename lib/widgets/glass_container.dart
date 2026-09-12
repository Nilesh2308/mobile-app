import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Reusable glassmorphism container with frosted blur, gradient border, and inner glow.
/// Adapts automatically between light and dark mode for optimal transparency.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blurIntensity,
    this.opacity,
    this.borderWidth = 1.0,
    this.borderGradient = false,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? blurIntensity;
  final double? opacity;
  final double borderWidth;
  final bool borderGradient;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.borderR16;
    final sigma = blurIntensity ?? (isDark ? AppColors.glassBlurSigma : AppColors.glassBlurLight);
    final overlayOpacity = opacity ?? (isDark ? 0.08 : 0.6);

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            padding: padding ?? AppSpacing.p16,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.white).withValues(alpha: overlayOpacity),
              borderRadius: radius,
              border: borderGradient
                  ? null
                  : Border.all(
                      color: colors.glassBorder,
                      width: borderWidth,
                    ),
              gradient: borderGradient
                  ? null
                  : null,
            ),
            foregroundDecoration: borderGradient
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                      width: borderWidth,
                    ),
                  )
                : null,
            child: child,
          ),
        ),
      ),
    );
  }
}
