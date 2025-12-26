import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageOnboardingGate {
  static const _sessionKey = 'language_sheet_shown_session';

  /// ✅ Mostrar SOLO una vez "por login".
  /// (Se resetea en logout llamando resetSession()).
  static Future<void> showOncePerSession(
    BuildContext context, {
    required Future<void> Function(String code) onConfirm,
    required String initialCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool(_sessionKey) ?? false;

    if (alreadyShown) return;

    // Marca como mostrado ANTES de abrir para evitar doble apertura
    await prefs.setBool(_sessionKey, true);

    if (!context.mounted) return;

    await show(context, onConfirm: onConfirm, initialCode: initialCode);
  }

  /// 👉 Mostrar siempre (uso interno)
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String code) onConfirm,
    required String initialCode,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) =>
          _LanguageSheet(onConfirm: onConfirm, initialCode: initialCode),
    );
  }

  /// ✅ Llamar esto SIEMPRE al hacer logout
  static Future<void> resetSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}

// =======================================================
// SHEET
// =======================================================

class _LanguageSheet extends StatefulWidget {
  final Future<void> Function(String code) onConfirm;
  final String initialCode;

  const _LanguageSheet({required this.onConfirm, required this.initialCode});

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  late String _selected;
  late String _previous;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCode;
    _previous = widget.initialCode;
  }

  Future<void> _select(String code) async {
    if (_selected == code) return;

    HapticFeedback.selectionClick();
    setState(() => _selected = code);

    // 🔁 Preview inmediato del idioma (solo UI)
    await context.setLocale(Locale(code));
  }

  Future<void> _cancel() async {
    // Volver al idioma anterior
    await context.setLocale(Locale(_previous));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    HapticFeedback.lightImpact();

    // Cierra primero (premium feel)
    Navigator.of(context).pop();

    // Persiste idioma + refresh (lo hace el callback)
    await widget.onConfirm(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F0F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'language_onboarding.title'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'language_onboarding.subtitle'.tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            _tile('es', '🇪🇸', 'Español'),
            _tile('en', '🇬🇧', 'English'),
            _tile('pt', '🇧🇷', 'Português'),
            _tile('fr', '🇫🇷', 'Français'),
            _tile('it', '🇮🇹', 'Italiano'),
            _tile('ja', '🇯🇵', '日本語'),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'language_onboarding.confirm'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            TextButton(
              onPressed: _cancel,
              child: Text(
                'language_onboarding.skip'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String code, String flag, String label) {
    final selected = _selected == code;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Colors.white : Colors.white12,
          width: selected ? 1.2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () => _select(code),
        leading: Text(flag, style: const TextStyle(fontSize: 18)),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}
