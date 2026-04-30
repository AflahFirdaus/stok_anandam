import 'package:flutter/material.dart';

import 'app_spacing.dart';

/// Design system: tema aplikasi (light & dark).
/// Gunakan Theme.of(context).colorScheme dan textTheme di widget.
class AppTheme {
  AppTheme._();

  static const Color _seedLight = Color(0xFF1976D2);
  static const Color _seedDark = Color(0xFF90CAF9);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedLight,
      brightness: Brightness.light,
      primary: const Color(0xFF1976D2),
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      textTheme: _textTheme,
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        color: colorScheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.snackBar)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedDark,
      brightness: Brightness.dark,
      primary: const Color(0xFF90CAF9),
      surface: const Color(0xFF1E1E1E),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      textTheme: _textTheme,
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        color: colorScheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.snackBar)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontSize: 14),
    bodyMedium: TextStyle(fontSize: 12),
    bodySmall: TextStyle(fontSize: 10),
    labelLarge: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}
