import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider del idioma actual (slug: es/en/pt/fr/it/ja)
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref);
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier(this.ref) : super('es');

  final Ref ref;

  /// ✅ Cambia idioma de forma segura y consistente.
  /// Retorna true si cambió, false si era el mismo.
  Future<bool> setLanguage(BuildContext context, String code) async {
    final normalized = _normalize(code);

    if (state == normalized) return false;

    state = normalized;

    // ✅ cambia el locale en easy_localization
    // OJO: easy_localization espera Locale('es'), Locale('en'), etc.
    await context.setLocale(Locale(normalized));

    return true;
  }

  String _normalize(String code) {
    var c = code.trim().toLowerCase();

    // soportar ja_JP / ja-JP etc.
    c = c.replaceAll('_', '-');
    if (c.contains('-')) c = c.split('-').first;

    // alias
    if (c == 'jp') c = 'ja';

    // whitelist (tu app)
    const allowed = {'es', 'en', 'pt', 'fr', 'it', 'ja'};
    if (!allowed.contains(c)) return 'es';

    return c;
  }
}
