import 'package:flutter/material.dart';

/// Central 4/8pt spacing scale and layout tokens.
/// Strictly avoid hardcoded arbitrary padding/margin numbers in widget code.
abstract final class AppSpacing {
  // Base 4/8pt spacing constants
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double s12 = 12.0;
  static const double s14 = 14.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // All-sides EdgeInsets
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p6 = EdgeInsets.all(s6);
  static const EdgeInsets p8 = EdgeInsets.all(s8);
  static const EdgeInsets p10 = EdgeInsets.all(s10);
  static const EdgeInsets p12 = EdgeInsets.all(s12);
  static const EdgeInsets p16 = EdgeInsets.all(s16);
  static const EdgeInsets p20 = EdgeInsets.all(s20);
  static const EdgeInsets p24 = EdgeInsets.all(s24);
  static const EdgeInsets p32 = EdgeInsets.all(s32);

  // Horizontal EdgeInsets
  static const EdgeInsets px8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets px12 = EdgeInsets.symmetric(horizontal: s12);
  static const EdgeInsets px16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets px20 = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets px24 = EdgeInsets.symmetric(horizontal: s24);

  // Vertical EdgeInsets
  static const EdgeInsets py4 = EdgeInsets.symmetric(vertical: s4);
  static const EdgeInsets py8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets py12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets py16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets py20 = EdgeInsets.symmetric(vertical: s20);
  static const EdgeInsets py24 = EdgeInsets.symmetric(vertical: s24);

  // Screen padding standard
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: s16, vertical: s12);

  // Vertical SizedBox spacers
  static const Widget vGap2 = SizedBox(height: s2);
  static const Widget vGap4 = SizedBox(height: s4);
  static const Widget vGap6 = SizedBox(height: s6);
  static const Widget vGap8 = SizedBox(height: s8);
  static const Widget vGap12 = SizedBox(height: s12);
  static const Widget vGap16 = SizedBox(height: s16);
  static const Widget vGap20 = SizedBox(height: s20);
  static const Widget vGap24 = SizedBox(height: s24);
  static const Widget vGap32 = SizedBox(height: s32);
  static const Widget vGap48 = SizedBox(height: s48);

  // Horizontal SizedBox spacers
  static const Widget hGap4 = SizedBox(width: s4);
  static const Widget hGap6 = SizedBox(width: s6);
  static const Widget hGap8 = SizedBox(width: s8);
  static const Widget hGap10 = SizedBox(width: s10);
  static const Widget hGap12 = SizedBox(width: s12);
  static const Widget hGap16 = SizedBox(width: s16);
  static const Widget hGap20 = SizedBox(width: s20);
  static const Widget hGap24 = SizedBox(width: s24);
  static const Widget hGap32 = SizedBox(width: s32);
}

/// Standard border radius tokens across the application
abstract final class AppRadius {
  static const double r4 = 4.0;
  static const double r6 = 6.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r12 = 12.0;
  static const double r14 = 14.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double rFull = 9999.0;

  static const BorderRadius borderR6 = BorderRadius.all(Radius.circular(r6));
  static const BorderRadius borderR8 = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius borderR10 = BorderRadius.all(Radius.circular(r10));
  static const BorderRadius borderR12 = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius borderR14 = BorderRadius.all(Radius.circular(r14));
  static const BorderRadius borderR16 = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius borderR20 = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius borderR24 = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius borderRFull = BorderRadius.all(Radius.circular(rFull));
}

/// Subtle SaaS Elevation Shadows (No harsh Material 2 drop shadows)
abstract final class AppShadows {
  /// Subtle card shadow for light mode
  static const List<BoxShadow> lightCard = [
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0F000000), // 6% black
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
  ];

  /// Subtle elevated/modal shadow for light mode
  static const List<BoxShadow> lightElevated = [
    BoxShadow(
      color: Color(0x14000000), // 8% black
      offset: Offset(0, 8),
      blurRadius: 20,
      spreadRadius: -4,
    ),
  ];

  /// Subtle glow for dark mode
  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Shadow selector based on dark mode
  static List<BoxShadow> card(bool isDark) => isDark ? darkCard : lightCard;
}
