import 'package:disfruta_antofagasta/shared/provider/auth_mode_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuthTabBar extends StatelessWidget {
  final AuthMode value;
  final ValueChanged<AuthMode> onChanged;
  final bool isForgotMode; // 👈 nuevo

  const AuthTabBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.isForgotMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final group = isForgotMode ? null : value; // 👈 desmarca en modo forgot

    return Opacity(
      opacity: isForgotMode ? 0.85 : 1,
      child: CupertinoSlidingSegmentedControl<AuthMode>(
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        thumbColor: Colors.white.withValues(alpha: 0.90),
        groupValue: group,
        padding: const EdgeInsets.all(6),
        children: const {
          AuthMode.login: _SegLabel('Iniciar sesión'),
          AuthMode.guest: _SegLabel('Invitado'),
          AuthMode.register: _SegLabel('Crear cuenta'),
        },
        onValueChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _SegLabel extends StatelessWidget {
  final String text;
  const _SegLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
