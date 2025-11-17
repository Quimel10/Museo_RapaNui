// lib/ui/auth/widgets/forms/login_form.dart
import 'package:disfruta_antofagasta/features/auth/presentation/state/login/login_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/widgets/rounded_field.dart';
import 'package:disfruta_antofagasta/shared/provider/forgot_mode_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _obscureProvider = StateProvider.autoDispose<bool>((_) => true);

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});
  @override
  ConsumerState<LoginForm> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginForm> {
  final _emailCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final storage = ref.read(keyValueStorageServiceProvider);
      final last = await storage.getValue<String>('email');
      if (!mounted) return;
      if (last != null && last.isNotEmpty) {
        _emailCtrl.text = last;
        // opcional: sincroniza el form state
        ref.read(loginFormProvider.notifier).onEmailChange(last);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(loginFormProvider);
    final obscure = ref.watch(_obscureProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoundedField(
          controller: _emailCtrl,

          hint: 'Correo electrónico',
          prefix: const Icon(Icons.mail_outlined),
          keyboardType: TextInputType.emailAddress,
          error: form.email.errorMessage,
          onChanged: (v) =>
              ref.read(loginFormProvider.notifier).onEmailChange(v),
        ),
        const SizedBox(height: 12),
        RoundedField(
          hint: 'Contraseña',
          obscureText: obscure,
          prefix: const Icon(Icons.lock_outline),
          error: form.password.errorMessage,

          suffix: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () =>
                ref.read(_obscureProvider.notifier).state = !obscure,
          ),
          onChanged: (v) =>
              ref.read(loginFormProvider.notifier).onPasswordChanged(v),
        ),
        const SizedBox(height: 10),

        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const StadiumBorder(),
              backgroundColor: const Color(0xFF0E4560),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            onPressed: form.isPosting
                ? null
                : () => ref.read(loginFormProvider.notifier).onFormSubmit(),
            child: Text(form.isPosting ? 'Ingresando…' : 'Iniciar sesión'),
          ),
        ),
        const SizedBox(height: 10),

        TextButton(
          onPressed: () => ref.read(forgotModeProvider.notifier).state = true,
          child: const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
