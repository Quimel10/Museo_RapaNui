// features/auth/presentation/state/forgot/forgot_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'forgot_state.dart';

typedef SendCodeFn = Future<void> Function(String email);
typedef ResetFn =
    Future<void> Function({
      required String email,
      required String code,
      required String newPassword,
    });

class ForgotNotifier extends StateNotifier<ForgotState> {
  ForgotNotifier({required this.sendCode, required this.reset})
    : super(const ForgotState());

  final SendCodeFn sendCode;
  final ResetFn reset;

  void setEmail(String v) => state = state.copyWith(email: v, error: null);
  void setCode(String v) => state = state.copyWith(code: v, error: null);
  void setPassword(String v) =>
      state = state.copyWith(newPassword: v, error: null);
  void togglePasswordVisibility() {
    state = state.copyWith(hidePassword: !state.hidePassword);
  }

  Future<void> submitEmail() async {
    if (state.email.trim().isEmpty) {
      state = state.copyWith(error: 'Ingresa tu correo');
      return;
    }
    state = state.copyWith(isPosting: true, error: null);
    try {
      await sendCode(state.email.trim());
      // Pasar a paso 2 aunque el backend responda genérico
      state = state.copyWith(step: ForgotStep.code);
    } catch (_) {
      state = state.copyWith(error: 'No pudimos enviar el código');
    } finally {
      state = state.copyWith(isPosting: false);
    }
  }

  Future<void> submitReset() async {
    if (state.code.trim().isEmpty) {
      state = state.copyWith(error: 'Ingresa el código');
      return;
    }
    if (state.newPassword.length < 6) {
      state = state.copyWith(error: 'La contraseña debe tener 6+ caracteres');
      return;
    }
    state = state.copyWith(isPosting: true, error: null);
    try {
      await reset(
        email: state.email.trim(),
        code: state.code.trim(),
        newPassword: state.newPassword,
      );
      // En éxito, AuthNotifier hará login automático (ver punto 3)
    } catch (_) {
      state = state.copyWith(error: 'No se pudo cambiar la contraseña');
    } finally {
      state = state.copyWith(isPosting: false);
    }
  }

  void backToLogin() => state = const ForgotState();
}
