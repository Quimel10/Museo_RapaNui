// lib/features/auth/presentation/form/forgot_form.dart
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/forgot/forgot_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/forgot/forgot_state.dart';
import 'package:disfruta_antofagasta/shared/provider/forgot_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotForm extends ConsumerWidget {
  const ForgotForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(forgotFormProvider);
    final n = ref.read(forgotFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título/ayuda
        Text(
          s.step == ForgotStep.email
              ? 'Recuperar contraseña'
              : 'Ingresa el código y tu nueva contraseña',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white, // 👈 TÍTULO EN BLANCO
          ),
        ),
        const SizedBox(height: 12),

        // Email
        TextFormField(
          initialValue: s.email,
          style: const TextStyle(color: Colors.black),
          onChanged: n.setEmail,
          readOnly: s.step == ForgotStep.code,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('Correo electrónico'),
        ),
        const SizedBox(height: 12),

        if (s.step == ForgotStep.code) ...[
          // Código
          TextFormField(
            onChanged: n.setCode,
            style: const TextStyle(color: Colors.black),
            decoration: _inputDecoration('Código de verificación'),
          ),
          const SizedBox(height: 12),

          // Nueva contraseña
          TextFormField(
            onChanged: n.setPassword,
            obscureText: s.hidePassword,
            obscuringCharacter: '•',
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(color: Colors.black),
            decoration: _inputDecoration('Nueva contraseña').copyWith(
              hintStyle: const TextStyle(color: Colors.black54),
              suffixIcon: IconButton(
                onPressed: n.togglePasswordVisibility,
                icon: Icon(
                  s.hidePassword ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: s.hidePassword ? 'Mostrar' : 'Ocultar',
              ),
              suffixIconColor: Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Si el correo existe, te enviamos un código. '
            'Ingresa el código y tu nueva contraseña para continuar.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white, // 👈 TEXTO AYUDA PASO 2 EN BLANCO
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          const Text(
            'Si el correo existe, te enviaremos un código para recuperar tu cuenta.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white, // 👈 TEXTO AYUDA PASO 1 EN BLANCO
            ),
          ),
          const SizedBox(height: 8),
        ],

        if (s.error != null) ...[
          Text(s.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
        ],

        // BOTÓN PRINCIPAL
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.panelWine,
              foregroundColor: AppColors.textOnPanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            onPressed: s.isPosting
                ? null
                : (s.step == ForgotStep.email ? n.submitEmail : n.submitReset),
            child: Text(
              s.isPosting
                  ? 'Enviando...'
                  : (s.step == ForgotStep.email
                        ? 'Enviar código'
                        : 'Cambiar clave'),
            ),
          ),
        ),
        const SizedBox(height: 8),

        TextButton(
          onPressed: () {
            ref.read(forgotModeProvider.notifier).state = false;
            n.backToLogin();
          },
          child: const Text(
            'Volver a iniciar sesión',
            style: TextStyle(
              color: Colors.white, // 👈 LINK EN BLANCO
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide(color: Color(0xFF0E4560), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        borderSide: BorderSide(color: Colors.red, width: 1.2),
      ),
    );
  }
}
