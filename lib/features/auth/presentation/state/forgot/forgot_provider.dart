// features/auth/presentation/state/forgot/forgot_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/auth/auth_provider.dart';
import 'forgot_notifier.dart';
import 'forgot_state.dart';

final forgotFormProvider =
    StateNotifierProvider.autoDispose<ForgotNotifier, ForgotState>((ref) {
      final auth = ref.read(authProvider.notifier);
      return ForgotNotifier(
        sendCode: auth.sendRecoveryCode,
        reset: ({required email, required code, required newPassword}) => auth
            .resetPassword(email: email, code: code, newPassword: newPassword),
      );
    });
