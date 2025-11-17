import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:flutter/material.dart';

/// Pequeño tema local aplicado solo dentro del Card de Auth.
/// Si luego quieres moverlo al Theme global, este archivo ya te lo deja fácil.
ThemeData buildAuthTheme() {
  return ThemeData(
    useMaterial3: false,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .88),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x220E4E78)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x220E4E78)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.blueDeep,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: Color(0x1F0E4E78)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        foregroundColor: AppColors.blueDeep,
        backgroundColor: Colors.white.withValues(alpha: .86),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x220E4E78),
      thickness: 1,
    ),
  );
}
