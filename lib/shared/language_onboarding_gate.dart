import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageOnboardingGate {
  static bool _shownThisSession = false;

  static Future<void> resetSession() async {
    _shownThisSession = false;
  }

  static String _normalize(String code) {
    final c = code.trim().toLowerCase().replaceAll('_', '-');
    if (c.isEmpty) return 'es';
    final base = c.split('-').first;
    if (base == 'jp') return 'ja';
    return base;
  }

  static Future<void> showOncePerSession(
    BuildContext context, {
    required List<String> allowedCodes,
    required String initialCode,
    required Future<void> Function(String code) onConfirm,
  }) async {
    if (_shownThisSession) return;
    _shownThisSession = true;

    // ✅ Idiomas soportados por EasyLocalization
    final supported = context.supportedLocales
        .map((l) => l.languageCode.toLowerCase())
        .toSet();

    // ✅ normaliza y filtra
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

    await showModalBottomSheet(
      context: context,
      isDismissible: true,
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
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

                        // ✅ AQUÍ ESTÁ EL FIX: al tocar la fila, cambiar locale de verdad
                        ...normalized.map((code) {
                          final isSel = code == selected;
                          return InkWell(
                            onTap: () async {
                              // 1) marcar selección visual
                              setState(() => selected = code);

                              // 2) traducir INMEDIATO al tocar idioma
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

                        const SizedBox(height: 4),
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

                              // ✅ Mantén tu flujo: aquí haces lo que necesites
                              // (guardar idioma, refrescar data, llamar API, etc.)
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
