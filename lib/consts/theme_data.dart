import 'package:flutter/material.dart';
import 'package:notes_hub/consts/app_colors.dart';

class Styles {
  static ThemeData themeData({
    required bool isDarkTheme,
    required BuildContext context,
  }) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimary,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme.copyWith(
        primary: isDarkTheme ? AppColors.darkPrimary : AppColors.lightPrimary,
        secondary: AppColors.accent,
        surface: isDarkTheme ? const Color(0xFF121C2E) : Colors.white,
      ),
      scaffoldBackgroundColor: isDarkTheme
          ? AppColors.darkScaffoldColor
          : AppColors.lightScaffoldColor,
      cardColor: isDarkTheme ? const Color(0xFF121C2E) : AppColors.lightCardColor,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      dividerColor: isDarkTheme
          ? Colors.white.withValues(alpha: 0.08)
          : AppColors.textDark.withValues(alpha: 0.08),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
          color: isDarkTheme ? AppColors.textLight : AppColors.textDark,
        ),
        backgroundColor: isDarkTheme
            ? AppColors.darkScaffoldColor
            : AppColors.lightScaffoldColor,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isDarkTheme ? AppColors.textLight : AppColors.textDark,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDarkTheme ? const Color(0xFF10192A) : Colors.white,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? (isDarkTheme ? AppColors.textLight : AppColors.textDark)
                : AppColors.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
        indicatorColor: (isDarkTheme
                ? AppColors.darkPrimary
                : AppColors.lightPrimary)
            .withValues(alpha: 0.16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDarkTheme ? const Color(0xFF121C2E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              isDarkTheme ? AppColors.darkPrimary : AppColors.lightPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDarkTheme
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        hintStyle: const TextStyle(color: AppColors.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: isDarkTheme
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.textDark.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.4,
            color: isDarkTheme ? AppColors.darkPrimary : AppColors.lightPrimary,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.2,
            color: Theme.of(context).colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
