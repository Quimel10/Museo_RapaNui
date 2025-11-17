// features/auth/presentation/form/forgot_form.dart
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
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),

        // Email (siempre visible; en paso 2 lo dejamos readOnly)
        TextFormField(
          initialValue: s.email,
          style: TextStyle(color: Colors.black),
          onChanged: n.setEmail,
          readOnly: s.step == ForgotStep.code,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Correo electrónico',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.92),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (s.step == ForgotStep.code) ...[
          TextFormField(
            onChanged: n.setCode,
            style: TextStyle(color: Colors.black),

            decoration: InputDecoration(
              hintText: 'Código de verificación',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.92),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            onChanged: n.setPassword,
            obscureText: s.hidePassword, // <-- usa la bandera
            obscuringCharacter: '•',
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Nueva contraseña',
              hintStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.92),
              suffixIcon: IconButton(
                // <-- botón para ver/ocultar
                onPressed:
                    n.togglePasswordVisibility, // cambia el bool en el notifier
                icon: Icon(
                  s.hidePassword ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: s.hidePassword ? 'Mostrar' : 'Ocultar',
              ),
              suffixIconColor:
                  Colors.black45, // fija color en dark mode también
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Si el correo existe, te enviamos un código. '
            'Ingresa el código y tu nueva contraseña para continuar.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
        ] else ...[
          const Text(
            'Si el correo existe, te enviaremos un código para recuperar tu cuenta.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],

        if (s.error != null) ...[
          Text(s.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
        ],

        SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              backgroundColor: const Color(0xFF0E4560),
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
            // volver al login
            ref.read(forgotModeProvider.notifier).state = false;
            n.backToLogin();
          },
          child: const Text(
            'Volver a iniciar sesión',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
