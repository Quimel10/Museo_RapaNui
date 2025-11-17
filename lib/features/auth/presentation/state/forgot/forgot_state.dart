// features/auth/presentation/state/forgot/forgot_state.dart
enum ForgotStep { email, code }

class ForgotState {
  final String email;
  final String code;
  final String newPassword;
  final bool isPosting;
  final bool hidePassword;
  final String? error;
  final ForgotStep step;

  const ForgotState({
    this.email = '',
    this.code = '',
    this.hidePassword = true,
    this.newPassword = '',
    this.isPosting = false,
    this.error,
    this.step = ForgotStep.email,
  });

  ForgotState copyWith({
    String? email,
    String? code,
    String? newPassword,
    bool? isPosting,
    bool? hidePassword,
    String? error,
    ForgotStep? step,
  }) => ForgotState(
    hidePassword: hidePassword ?? this.hidePassword,
    email: email ?? this.email,
    code: code ?? this.code,
    newPassword: newPassword ?? this.newPassword,
    isPosting: isPosting ?? this.isPosting,
    error: error,
    step: step ?? this.step,
  );
}
