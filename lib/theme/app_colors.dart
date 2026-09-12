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

  // ─── NEON GLOW COLORS (Voice States) ─────────────────────────
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonMagenta = Color(0xFFFF006E);
  static const Color neonPurple = Color(0xFFBB86FC);
  static const Color neonBlue = Color(0xFF4D7CFF);
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonOrange = Color(0xFFFF9100);
  static const Color auroraViolet = Color(0xFF7C4DFF);
  static const Color auroraTeal = Color(0xFF1DE9B6);

  // ─── GRADIENT PRESETS ─────────────────────────────────────────

  /// Dark mesh background gradients (organic, alive)
  static const List<Color> meshDarkBase = [
    Color(0xFF050510), // Deep space
    Color(0xFF0A0A1F), // Midnight indigo
    Color(0xFF0D0820), // Dark violet
    Color(0xFF060612), // Ink
  ];

  /// Light mesh background gradients (subtle, elegant)
  static const List<Color> meshLightBase = [
    Color(0xFFF8F9FF), // Soft lavender white
    Color(0xFFEEF0FF), // Pale indigo
    Color(0xFFF5F3FF), // Light violet
    Color(0xFFF0F4FF), // Ice blue
  ];

  /// Voice idle gradient (calm purple/blue aura)
  static const List<Color> voiceIdleGradient = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF7C3AED), // Violet
    Color(0xFF6366F1), // Primary
  ];

  /// Voice listening gradient (hot red/magenta pulse)
  static const List<Color> voiceListeningGradient = [
    Color(0xFFFF006E), // Hot magenta
    Color(0xFFFF3D71), // Coral
    Color(0xFFFF1744), // Red accent
  ];

  /// Voice transcribing gradient (amber/orange spin)
  static const List<Color> voiceTranscribingGradient = [
    Color(0xFFFF9100), // Orange
    Color(0xFFFFC107), // Amber
    Color(0xFFFFAB00), // Gold
  ];

  /// Voice thinking gradient (cyan/blue pulse)
  static const List<Color> voiceThinkingGradient = [
    Color(0xFF00B8D4), // Cyan
    Color(0xFF4D7CFF), // Electric blue
    Color(0xFF6366F1), // Indigo
  ];

  /// Voice speaking gradient (emerald/teal wave)
  static const List<Color> voiceSpeakingGradient = [
    Color(0xFF00E676), // Neon green
    Color(0xFF1DE9B6), // Aurora teal
    Color(0xFF00BFA5), // Teal
  ];

  /// User chat bubble gradient
  static const List<Color> userBubbleGradient = [
    Color(0xFF6366F1), // Primary
    Color(0xFF7C3AED), // Violet
  ];

  /// Brand accent gradient (for buttons, highlights)
  static const List<Color> brandGradient = [
    Color(0xFF6366F1), // Primary
    Color(0xFF818CF8), // Primary 400
    Color(0xFF7C3AED), // Violet accent
  ];

  // ─── GLASSMORPHISM TOKENS ─────────────────────────────────────
  static const double glassBlurSigma = 24.0;
  static const double glassBlurLight = 16.0;
  static const double glassBlurHeavy = 40.0;

  static const Color glassDarkOverlay = Color(0x1AFFFFFF); // 10% white
  static const Color glassDarkBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassLightOverlay = Color(0x80FFFFFF); // 50% white
  static const Color glassLightBorder = Color(0x4DFFFFFF); // 30% white
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
    required this.glassOverlay,
    required this.glassBorder,
    required this.meshColors,
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
  final Color glassOverlay;
  final Color glassBorder;
  final List<Color> meshColors;

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
    glassOverlay: AppColors.glassLightOverlay,
    glassBorder: AppColors.glassLightBorder,
    meshColors: AppColors.meshLightBase,
  );

  /// Dark theme color palette (Linear/Vercel sleek dark style)
  static const dark = AppThemeColors(
    primary: AppColors.primary400,
    onPrimary: AppColors.gray950,
    primaryContainer: Color(0xFF1A1A35),
    onPrimaryContainer: AppColors.primary200,
    background: Color(0xFF050510),
    surface: Color(0xFF0C0C1A),
    surfaceSecondary: Color(0xFF12122A),
    surfaceElevated: Color(0xFF181830),
    borderSubtle: Color(0xFF1E1E3A),
    borderStrong: Color(0xFF2E2E50),
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
    glassOverlay: AppColors.glassDarkOverlay,
    glassBorder: AppColors.glassDarkBorder,
    meshColors: AppColors.meshDarkBase,
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
    Color? glassOverlay,
    Color? glassBorder,
    List<Color>? meshColors,
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
      glassOverlay: glassOverlay ?? this.glassOverlay,
      glassBorder: glassBorder ?? this.glassBorder,
      meshColors: meshColors ?? this.meshColors,
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
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      meshColors: meshColors, // Lists don't lerp linearly
    );
  }
}
