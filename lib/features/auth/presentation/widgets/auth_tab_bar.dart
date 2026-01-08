// lib/features/auth/presentation/widgets/auth_tab_bar.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:disfruta_antofagasta/shared/provider/auth_mode_provider.dart';

class AuthTabBar extends StatelessWidget {
  final AuthMode value;
  final ValueChanged<AuthMode> onChanged;
  final bool isForgotMode;

  const AuthTabBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.isForgotMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Si estás en forgot mode, tu SDK no acepta onValueChanged nullable.
    // Así que no mostramos el segmented.
    if (isForgotMode) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ✅ FIX: evita crash de layout cuando el ancho llega a 0
          if (constraints.maxWidth <= 1) {
            return const SizedBox(height: 44);
          }

          return SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<AuthMode>(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: Colors.white.withValues(alpha: 0.90),
              groupValue: value,
              padding: const EdgeInsets.all(6),
              children: {
                AuthMode.login: _SegLabel(
                  'Iniciar sesión',
                  selected: value == AuthMode.login,
                ),
                AuthMode.guest: _SegLabel(
                  'Invitado',
                  selected: value == AuthMode.guest,
                ),
                AuthMode.register: _SegLabel(
                  'Crear cuenta',
                  selected: value == AuthMode.register,
                ),
              },

              // ✅ En tu Flutter: NO puede ser null
              // y recibe AuthMode? (puede venir null)
              onValueChanged: (AuthMode? v) {
                if (v == null) return;
                onChanged(v);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SegLabel extends StatelessWidget {
  final String text;
  final bool selected;

  const _SegLabel(this.text, {required this.selected});

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
