import 'package:flutter/material.dart';

/// Central design tokens for colors across the application.
/// Strictly avoid inline ad-hoc colors in widgets.
abstract final class AppColors {
  // Brand Accent (Linear / Modern SaaS Indigo)
  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary300 = Color(0xFFA5B4FC);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary500 = Color(0xFF6366F1); // Signature Brand Accent
  static const Color primary600 = Color(0xFF4F46E5);
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary800 = Color(0xFF3730A3);
  static const Color primary900 = Color(0xFF312E81);

  // 11-step Neutral Grayscale (Zinc / Slate inspired)
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF4F4F5);
  static const Color gray200 = Color(0xFFE4E4E7);
  static const Color gray300 = Color(0xFFD4D4D8);
  static const Color gray400 = Color(0xFFA1A1AA);
  static const Color gray500 = Color(0xFF71717A);
  static const Color gray600 = Color(0xFF52525B);
  static const Color gray700 = Color(0xFF3F3F46);
  static const Color gray800 = Color(0xFF27272A);
  static const Color gray900 = Color(0xFF18181B);
  static const Color gray950 = Color(0xFF09090B);

  // Semantic: Success (Emerald)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successDark = Color(0xFF064E3B);
  static const Color successBorder = Color(0xFFA7F3D0);

  // Semantic: Warning (Amber)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningDark = Color(0xFF78350F);
  static const Color warningBorder = Color(0xFFFDE68A);

  // Semantic: Error (Rose / Red)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color errorDark = Color(0xFF7F1D1D);
  static const Color errorBorder = Color(0xFFFECACA);

  // Semantic: Info (Sky)
  static const Color info = Color(0xFF0EA5E9);
  static const Color infoLight = Color(0xFFF0F9FF);
  static const Color infoDark = Color(0xFF0C4A6E);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Constants
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}

/// ThemeExtension providing semantic theme colors for Light and Dark modes.
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.borderSubtle,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.error,
    required this.errorContainer,
    required this.onErrorContainer,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceElevated;
  final Color borderSubtle;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;

  /// Light theme color palette
  static const light = AppThemeColors(
    primary: AppColors.primary600,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primary50,
    onPrimaryContainer: AppColors.primary700,
    background: AppColors.white,
    surface: AppColors.gray50,
    surfaceSecondary: AppColors.gray100,
    surfaceElevated: AppColors.white,
    borderSubtle: AppColors.gray200,
    borderStrong: AppColors.gray300,
    textPrimary: AppColors.gray950,
    textSecondary: AppColors.gray600,
    textMuted: AppColors.gray400,
    success: AppColors.success,
    successContainer: AppColors.successLight,
    onSuccessContainer: AppColors.successDark,
    warning: AppColors.warning,
    warningContainer: AppColors.warningLight,
    onWarningContainer: AppColors.warningDark,
    error: AppColors.error,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.errorDark,
  );

  /// Dark theme color palette (Linear/Vercel sleek dark style)
  static const dark = AppThemeColors(
    primary: AppColors.primary400,
    onPrimary: AppColors.gray950,
    primaryContainer: Color(0xFF1E1E38),
    onPrimaryContainer: AppColors.primary200,
    background: AppColors.gray950,
    surface: Color(0xFF111114),
    surfaceSecondary: Color(0xFF18181D),
    surfaceElevated: Color(0xFF1F1F26),
    borderSubtle: Color(0xFF272730),
    borderStrong: Color(0xFF3F3F4E),
    textPrimary: AppColors.gray50,
    textSecondary: AppColors.gray400,
    textMuted: AppColors.gray500,
    success: Color(0xFF34D399),
    successContainer: Color(0xFF063726),
    onSuccessContainer: Color(0xFFA7F3D0),
    warning: Color(0xFFFBBF24),
    warningContainer: Color(0xFF452202),
    onWarningContainer: Color(0xFFFDE68A),
    error: Color(0xFFF87171),
    errorContainer: Color(0xFF450A0A),
    onErrorContainer: Color(0xFFFECACA),
  );

  /// Access colors via `AppThemeColors.of(context)`
  static AppThemeColors of(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>();
    return colors ?? (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  ThemeExtension<AppThemeColors> copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? borderSubtle,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? error,
    Color? errorContainer,
    Color? onErrorContainer,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    covariant ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
    );
  }
}
