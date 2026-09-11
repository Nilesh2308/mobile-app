import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// App-wide theme definitions for Light and Dark modes.
abstract final class AppTheme {
  /// Light ThemeData
  static ThemeData get light {
    final colors = AppThemeColors.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: AppColors.primary500,
        onSecondary: AppColors.white,
        error: colors.error,
        onError: AppColors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.borderSubtle,
      ),
      textTheme: AppTextStyles.textTheme(isDark: false),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      extensions: const <ThemeExtension<dynamic>>[
        AppThemeColors.light,
      ],
    );
  }

  /// Dark ThemeData
  static ThemeData get dark {
    final colors = AppThemeColors.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: AppColors.primary400,
        onSecondary: AppColors.gray950,
        error: colors.error,
        onError: AppColors.gray950,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        outline: colors.borderSubtle,
      ),
      textTheme: AppTextStyles.textTheme(isDark: true),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      extensions: const <ThemeExtension<dynamic>>[
        AppThemeColors.dark,
      ],
    );
  }
}

/// Controller for managing and toggling the active ThemeMode.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initialMode = ThemeMode.dark}) : _themeMode = initialMode;

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

/// InheritedWidget providing easy access to ThemeController in widget tree.
class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ThemeController controller;

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'No AppThemeScope found in context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(covariant AppThemeScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
