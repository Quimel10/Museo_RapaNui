import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VisitorType { rapanui, continental, foreign }

extension VisitorTypeX on VisitorType {
  String get key {
    switch (this) {
      case VisitorType.rapanui:
        return 'rapanui';
      case VisitorType.continental:
        return 'continental';
      case VisitorType.foreign:
        return 'foreign';
    }
  }

  static VisitorType? fromKey(String? v) {
    switch (v) {
      case 'rapanui':
        return VisitorType.rapanui;
      case 'continental':
        return VisitorType.continental;
      case 'foreign':
        return VisitorType.foreign;
      default:
        return null;
    }
  }
}

const _kVisitorTypeKey = 'visitor_type';

final visitorTypeProvider =
    StateNotifierProvider<VisitorTypeNotifier, VisitorType?>(
      (ref) => VisitorTypeNotifier(),
    );

class VisitorTypeNotifier extends StateNotifier<VisitorType?> {
  VisitorTypeNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kVisitorTypeKey);
    state = VisitorTypeX.fromKey(v);
  }

  Future<void> setType(VisitorType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVisitorTypeKey, type.key);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kVisitorTypeKey);
  }
}

/// Gate helper: si no hay tipo elegido, obliga a elegirlo.
/// Devuelve true si quedó elegido (o ya estaba).
class VisitorTypeGate {
  static Future<bool> ensureSelected(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(visitorTypeProvider);
    if (current != null) return true;

    final selected = await showModalBottomSheet<VisitorType>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VisitorTypeSheet(),
    );

    if (selected == null) return false;

    await ref.read(visitorTypeProvider.notifier).setType(selected);
    return true;
  }
}

class _VisitorTypeSheet extends ConsumerWidget {
  const _VisitorTypeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text(
              'Tipo de visitante',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Antes de continuar, selecciona una opción.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 14),
            _OptionTile(
              title: 'Local (Rapa Nui)',
              subtitle: 'Residente de Rapa Nui',
              onTap: () => Navigator.pop(context, VisitorType.rapanui),
            ),
            const SizedBox(height: 10),
            _OptionTile(
              title: 'Continental',
              subtitle: 'Residente de Chile continental',
              onTap: () => Navigator.pop(context, VisitorType.continental),
            ),
            const SizedBox(height: 10),
            _OptionTile(
              title: 'Extranjero',
              subtitle: 'Residente fuera de Chile',
              onTap: () => Navigator.pop(context, VisitorType.foreign),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1C),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
