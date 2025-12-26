// lib/config/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_config.dart';

class AppTheme {
  /// ✅ Queremos negro + blanco SIEMPRE.
  /// Por eso light() y dark() devuelven el mismo ThemeData oscuro.
  static ThemeData light() => _museumDarkTheme();
  static ThemeData dark() => _museumDarkTheme();

  static ThemeData _museumDarkTheme() {
    // ColorScheme “oscuro” consistente (mantenemos el primary naranja para links/acento general)
    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,

      primary: AppColors.orangePrimary,
      onPrimary: AppColors.neutral50,

      secondary: AppColors.bluePrimaryLight,
      onSecondary: AppColors.neutral50,

      tertiary: AppColors.orangePrimary,
      onTertiary: AppColors.neutral50,

      error: AppColors.error,
      onError: AppColors.neutral50,

      background: AppColors.parchment, // negro
      onBackground: AppColors.neutral50, // blanco

      surface: AppColors.panel, // tarjetas
      onSurface: AppColors.neutral50,

      surfaceVariant: AppColors.panelDark,
      onSurfaceVariant: AppColors.neutral100,

      outline: Color(0xFF2A2A2A),
      outlineVariant: Color(0xFF1F1F1F),

      shadow: Colors.black,
      scrim: Colors.black,

      inverseSurface: AppColors.neutral50,
      onInverseSurface: AppColors.neutral900,

      inversePrimary: AppColors.orangePrimary,
    );

    final baseTextTheme = GoogleFonts.latoTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: AppColors.parchment,

      // ✅ Loader "Cargando" SIEMPRE blanco
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Colors.white,
        circularTrackColor: Color(0x33FFFFFF),
      ),

      // ✅ Sliders (mini reproductor + slider de audio) en blanco
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white24,
        thumbColor: Colors.white,
        overlayColor: Colors.white24,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),

      // Textos globales en blanco / grises claros
      textTheme: baseTextTheme.copyWith(
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: colorScheme.onBackground.withOpacity(0.90),
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: colorScheme.onBackground.withOpacity(0.88),
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: colorScheme.onBackground.withOpacity(0.70),
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onBackground,
        ),
      ),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.neutral800,
        foregroundColor: colorScheme.onBackground,
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),

      cardTheme: CardThemeData(
        elevation: 0.8,
        color: AppColors.panel,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      chipTheme: ChipThemeData(
        labelStyle: baseTextTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        backgroundColor: AppColors.panel,
        selectedColor: colorScheme.secondary.withValues(alpha: 0.22),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panel,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.panel,
        selectedItemColor: colorScheme.onBackground,
        unselectedItemColor: colorScheme.onBackground.withOpacity(0.55),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _buttonStyle(colorScheme.primary, colorScheme.onPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _buttonStyle(colorScheme.tertiary, colorScheme.onTertiary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(colorScheme.onBackground),
      ),

      dividerColor: const Color(0xFF2A2A2A),
    );
  }

  static ButtonStyle _buttonStyle(Color bg, Color fg) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      minimumSize: const Size(88, 44),
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

  static ButtonStyle _outlinedStyle(Color fg) {
    return OutlinedButton.styleFrom(
      foregroundColor: fg,
      side: BorderSide(color: fg.withOpacity(0.6), width: 1.2),
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
