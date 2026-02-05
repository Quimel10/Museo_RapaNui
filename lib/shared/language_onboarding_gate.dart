// lib/shared/language_onboarding_gate.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageOnboardingGate {
  // ✅ Mostrar 1 vez por “ciclo de login”
  // - Se setea en true cuando ya se mostró (y persiste aunque cierres la app)
  // - Se borra al hacer logout
  static const String _kAuthShownThisLogin =
      'lang_onboarding_auth_shown_this_login';

  // ✅ Anti-doble show dentro del mismo run (por rebuild / navegación doble)
  static bool _shownThisRun = false;

  static String _normalize(String code) {
    final c = code.trim().toLowerCase().replaceAll('_', '-');
    if (c.isEmpty) return 'es';
    final base = c.split('-').first;
    if (base == 'jp') return 'ja';
    return base;
  }

  /// ✅ Llamar en LOGOUT: permite que en el próximo login vuelva a mostrar.
  static Future<void> clearForNextLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuthShownThisLogin);
    _shownThisRun = false;
  }

  /// ✅ Mostrar SOLO si:
  /// - el usuario está autenticado
  /// - y no se ha mostrado en ESTE ciclo de login (aunque cierres/abras app)
  ///
  /// Importante: guardamos el flag ANTES de abrir el modal para evitar la “segunda vez”.
  static Future<void> showOncePerLoginCycle(
    BuildContext context, {
    required List<String> allowedCodes,
    required String initialCode,
    required Future<void> Function(String code) onConfirm,
  }) async {
    if (_shownThisRun) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyShownThisLogin = prefs.getBool(_kAuthShownThisLogin) ?? false;
    if (alreadyShownThisLogin) return;

    // ✅ Bloqueo inmediato (evita que salga 2 veces por reconstrucciones)
    _shownThisRun = true;
    await prefs.setBool(_kAuthShownThisLogin, true);

    // ✅ Idiomas soportados por EasyLocalization
    final supported = context.supportedLocales
        .map((l) => l.languageCode.toLowerCase())
        .toSet();

    final normalized = allowedCodes
        .map(_normalize)
        .where((c) => supported.contains(c))
        .toSet()
        .toList();

    const order = ['es', 'en', 'pt', 'fr', 'it', 'ja'];
    normalized.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

    if (normalized.isEmpty) return;

    final current = supported.contains(_normalize(initialCode))
        ? _normalize(initialCode)
        : 'es';

    String selected = normalized.contains(current) ? current : normalized.first;

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: StatefulBuilder(
              builder: (ctx, setState) {
                final maxH = MediaQuery.of(ctx).size.height * 0.75;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'language_onboarding.title'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'language_onboarding.subtitle'.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...normalized.map((code) {
                          final isSel = code == selected;
                          return InkWell(
                            onTap: () async {
                              setState(() => selected = code);
                              await context.setLocale(Locale(code));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  isSel ? 0.12 : 0.06,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                      ? Colors.white.withOpacity(0.30)
                                      : Colors.white.withOpacity(0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _label(code),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isSel
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await onConfirm(selected);
                            },
                            child: Text('language_onboarding.confirm'.tr()),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(
                              'language_onboarding.skip'.tr(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  static String _label(String code) {
    switch (code) {
      case 'es':
        return '🇪🇸 Español';
      case 'en':
        return '🇬🇧 English';
      case 'pt':
        return '🇧🇷 Português';
      case 'fr':
        return '🇫🇷 Français';
      case 'it':
        return '🇮🇹 Italiano';
      case 'ja':
        return '🇯🇵 日本語';
      default:
        return code.toUpperCase();
    }
  }
}
