// lib/config/theme/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';
import 'theme_notifier.dart';

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((
  ref,
) {
  final notifier = ThemeNotifier();
  // Disparar la carga de prefs sin bloquear el árbol
  notifier.init();
  return notifier;
});

final lightThemeProvider = Provider<ThemeData>((_) => AppTheme.light());
final darkThemeProvider = Provider<ThemeData>((_) => AppTheme.dark());
