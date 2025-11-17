import 'package:disfruta_antofagasta/features/auth/presentation/state/login/login_state.dart';
import 'package:disfruta_antofagasta/shared/input/email.dart';
import 'package:disfruta_antofagasta/shared/input/password.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

class LoginFormNotifier extends StateNotifier<LoginState> {
  final Function(String, String) loginUserCallback;

  LoginFormNotifier({required this.loginUserCallback}) : super(LoginState());
  void onEmailChange(String value) {
    final newEmail = Email.dirty(value);
    state = state.copyWith(
      email: newEmail,
      isValid: Formz.validate([newEmail, state.password]),
    );
  }

  void onPasswordChanged(String value) {
    final newPassword = Password.dirty(value);
    state = state.copyWith(
      password: newPassword,
      isValid: Formz.validate([newPassword, state.email]),
    );
  }

  Future<void> onFormSubmit() async {
    _touchEveryField();

    if (!state.isValid) return;
    state = state.copyWith(isPosting: true);
    await loginUserCallback(state.email.value, state.password.value);
    state = state.copyWith(isPosting: false);
  }

  void _touchEveryField() {
    final email = Email.dirty(state.email.value);
    final password = Password.dirty(state.password.value);

    state = state.copyWith(
      isFormPosted: true,
      email: email,
      password: password,
      isValid: Formz.validate([email, password]),
    );
  }
}
