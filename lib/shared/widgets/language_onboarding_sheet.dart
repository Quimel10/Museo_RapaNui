import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageOnboardingSheet extends StatelessWidget {
  final List<Locale> supportedLocales;
  final Map<String, String> flagAssetByLocale;
  final Future<void> Function(Locale locale) onSelected;

  const LanguageOnboardingSheet({
    super.key,
    required this.supportedLocales,
    required this.flagAssetByLocale,
    required this.onSelected,
  });

  String _labelFor(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      case 'ja':
        return '日本語';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  String _emojiFor(Locale locale) {
    switch (locale.languageCode) {
      case 'es':
        return '🇪🇸';
      case 'en':
        return '🇬🇧';
      case 'pt':
        return '🇧🇷';
      case 'fr':
        return '🇫🇷';
      case 'it':
        return '🇮🇹';
      case 'ja':
        return '🇯🇵';
      default:
        return '🌐';
    }
  }

  Widget _flagWidget(Locale locale) {
    final key = locale.toString();
    final asset = flagAssetByLocale[key];

    if (asset == null || asset.isEmpty) return _emojiPill(locale);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 42,
        height: 30,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiPill(locale),
        ),
      ),
    );
  }

  Widget _emojiPill(Locale locale) {
    return Container(
      width: 42,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      child: Text(_emojiFor(locale), style: const TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = context.locale.languageCode;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0B0B), // negro museo
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Stack(
          children: [
            // Glow sutil superior
            Positioned(
              top: -80,
              left: -40,
              right: -40,
              child: IgnorePointer(
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.0,
                      colors: [
                        Colors.white.withOpacity(0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 12,
                bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'language_onboarding.title'.tr(),
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'language_onboarding.subtitle'.tr(),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withOpacity(0.70),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 14),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: supportedLocales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final locale = supportedLocales[i];
                        final isSelected = locale.languageCode == currentCode;

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            // ✅ cerrar primero para evitar glitch negro
                            Navigator.of(context).pop();
                            await Future.microtask(() => onSelected(locale));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: isSelected
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.22)
                                    : Colors.white.withOpacity(0.10),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.55),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _flagWidget(locale),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _labelFor(locale),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.92),
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.90)
                                          : Colors.white.withOpacity(0.25),
                                      width: 1.6,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.95,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Botón “Ahora no” premium (ghost)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.white.withOpacity(0.80),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: Text('language_onboarding.skip'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
