import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Central typography tokens using Google Fonts Inter for clean, confident SaaS aesthetics.
/// Never use Flutter's default Roboto look-and-feel.
abstract final class AppTextStyles {
  // Base font family name
  static const String fontFamily = 'Inter';

  /// Display Title: 28sp / w700 (Hero headers, major metric numbers)
  static TextStyle display({Color? color}) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.6,
        color: color,
      );

  /// Heading Large: 22sp / w600 (Screen headers, modal titles)
  static TextStyle headingLarge({Color? color}) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.4,
        color: color,
      );

  /// Heading Medium: 18sp / w600 (Card titles, section headers)
  static TextStyle headingMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
        color: color,
      );

  /// Heading Small: 15sp / w600 (Subsections, list group headers)
  static TextStyle headingSmall({Color? color}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
        color: color,
      );

  /// Body Large: 15sp / w400 (Lead paragraphs, primary chat messages)
  static TextStyle bodyLarge({Color? color, FontWeight? fontWeight}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 1.5,
        letterSpacing: -0.1,
        color: color,
      );

  /// Body Medium: 13sp / w400 (Standard UI labels, body text, inputs)
  static TextStyle bodyMedium({Color? color, FontWeight? fontWeight}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
        color: color,
      );

  /// Body Small: 12sp / w400 (Secondary descriptions, footnotes)
  static TextStyle bodySmall({Color? color, FontWeight? fontWeight}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w400,
        height: 1.4,
        letterSpacing: 0,
        color: color,
      );

  /// Label: 12sp / w600 (Button labels, pill tags, badges)
  static TextStyle label({Color? color, double letterSpacing = 0.1}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: letterSpacing,
        color: color,
      );

  /// Caption: 11sp / w400 (Timestamps, metadata tags)
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.3,
        letterSpacing: 0.1,
        color: color ?? AppColors.gray400,
      );

  /// Code / Technical Mono: 12sp / w500 (Latencies, model IDs, tokens)
  static TextStyle mono({Color? color, FontWeight? fontWeight}) => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: fontWeight ?? FontWeight.w500,
        height: 1.4,
        letterSpacing: -0.2,
        color: color,
      );

  /// Standard TextTheme builder configured with Inter
  static TextTheme textTheme({required bool isDark}) {
    final primary = isDark ? AppColors.gray50 : AppColors.gray950;
    final secondary = isDark ? AppColors.gray400 : AppColors.gray600;

    return TextTheme(
      displayLarge: display(color: primary),
      headlineLarge: headingLarge(color: primary),
      headlineMedium: headingMedium(color: primary),
      headlineSmall: headingSmall(color: primary),
      bodyLarge: bodyLarge(color: primary),
      bodyMedium: bodyMedium(color: primary),
      bodySmall: bodySmall(color: secondary),
      labelLarge: label(color: primary),
      labelMedium: label(color: secondary),
      labelSmall: caption(color: secondary),
    );
  }
}
