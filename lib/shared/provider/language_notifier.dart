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

  // 🌍 Idiomas soportados
  static const supported = {'es', 'en', 'pt', 'fr', 'it', 'ja'};

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);

    if (saved != null && supported.contains(saved)) {
      state = saved;
    } else {
      state = 'es';
    }
  }

  /// Cambia idioma y retorna true si realmente cambió (state anterior != nuevo).
  Future<bool> setLanguage(
    BuildContext context,
    WidgetRef ref,
    String lang,
  ) async {
    if (!supported.contains(lang)) return false;

    // Si es el mismo idioma, no hagas nada.
    if (state == lang && context.locale.languageCode == lang) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
    state = lang;

    // Cambiar locale de la app
    // ignore: use_build_context_synchronously
    await context.setLocale(Locale(lang));

    return true;
  }
}
