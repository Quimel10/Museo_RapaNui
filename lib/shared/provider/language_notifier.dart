import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>(
  (ref) => LanguageNotifier(),
);

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('es') {
    _load();
  }
  static const _key = 'language';
  static const supported = {'es', 'en', 'pt', 'fr'};

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    state = supported.contains(saved) ? saved! : 'es';
  }

  Future<void> setLanguage(
    BuildContext context,
    WidgetRef ref,
    String lang,
  ) async {
    if (!supported.contains(lang)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
    state = lang;

    // Cambia locale de la UI
    // ignore: use_build_context_synchronously
    await context.setLocale(Locale(lang));

    // si tienes más (ej: banners, favoritos con traducción) agrega aquí
  }
}
