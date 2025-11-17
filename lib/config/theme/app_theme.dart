import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_config.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.bluePrimaryDark,
      brightness: Brightness.light,
      primary: AppColors.bluePrimaryDark,
      secondary: AppColors.bluePrimaryLight,
      tertiary: AppColors.orangePrimary,
      onPrimary: Colors.white,
    );

    final baseTextTheme = GoogleFonts.latoTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.neutral900,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.neutral900,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.neutral800,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.neutral800,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700, // Botones en Bold
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.neutral900,
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        color: Colors.white,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        labelStyle: baseTextTheme.labelLarge?.copyWith(
          color: AppColors.neutral900,
        ),
        backgroundColor: AppColors.neutral100,
        selectedColor: colorScheme.secondary.withValues(alpha: 0.15),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: AppColors.neutral100),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.neutral100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.neutral700,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(colorScheme.primary, Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(colorScheme.tertiary, Colors.white),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(colorScheme.primary),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.bluePrimaryDark,
      brightness: Brightness.dark,
      primary: AppColors.bluePrimaryLight,
      secondary: AppColors.bluePrimaryLight,
      tertiary: AppColors.orangePrimary,
    );

    final baseTextTheme = GoogleFonts.latoTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0.8,
        color: const Color(0xFF111827),
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        labelStyle: baseTextTheme.labelLarge,
        backgroundColor: const Color(0xFF111827),
        selectedColor: colorScheme.secondary.withValues(alpha: 0.22),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0B1220),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0B1220),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.white.withAlpha(68),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(colorScheme.primary, Colors.white),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(colorScheme.secondary, AppColors.neutral900),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(colorScheme.primary),
      ),
    );
  }

  static ButtonStyle _buttonStyle(Color bg, Color fg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      minimumSize: const Size(88, 44), // A11y
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700),
    ).merge(
      ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return Colors.white.withValues(alpha: 0.12);
          }
          return null;
        }),
      ),
    );
  }

  static ButtonStyle _outlinedStyle(Color primary) {
    return OutlinedButton.styleFrom(
      foregroundColor: primary,
      side: BorderSide(color: primary, width: 1.2),
      minimumSize: const Size(88, 44),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      textStyle: GoogleFonts.lato(fontWeight: FontWeight.w700),
    );
  }
}
