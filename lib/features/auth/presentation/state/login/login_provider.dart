import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/login/login_notifier.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/login/login_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFormNotifier, LoginState>((ref) {
      final loginUserCallback = ref.watch(authProvider.notifier).loginUser;

      return LoginFormNotifier(loginUserCallback: loginUserCallback);
    });
