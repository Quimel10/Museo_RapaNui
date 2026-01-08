// lib/features/auth/presentation/state/auth/auth_notifier.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';
import 'package:disfruta_antofagasta/features/auth/domain/repositories/auth_repository.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_state.dart';
import 'package:disfruta_antofagasta/shared/services/key_value_storage_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  final KeyValueStorageService keyValueStorageService;

  AuthNotifier({
    required this.authRepository,
    required this.keyValueStorageService,
  }) : super(AuthState()) {
    checkAuthStatus();
  }

  // ======================
  // GUEST ✅ ENVÍA visitorType
  // ======================
  Future<void> guestUser(Guest guest) async {
    try {
      state = state.copyWith(errorMessage: null);

      final auth = await authRepository.guest(
        name: (guest.name ?? '').trim(),
        countryCode: (guest.countryCode ?? '').trim(),
        regionId: guest.regionId,
        age: guest.age,
        daysStay: guest.daysStay,

        // ✅ CLAVE: esto es lo que faltaba
        visitorType: guest.visitorType,
      );

      if (auth == null) {
        throw Exception('Respuesta nula del backend');
      }

      _setLoggedUser(auth);
    } catch (e) {
      final msg = _extractAnyErrorMessage(e);
      state = state.copyWith(
        authStatus: AuthStatus.notAuthenticated,
        errorMessage: msg,
        errorSeq: state.errorSeq + 1,
      );
    }
  }

  // ======================
  // REGISTER
  // ======================
  Future<void> registerUser(RegisterUser req) async {
    try {
      state = state.copyWith(errorMessage: null);
      final auth = await authRepository.register(req);
      _setLoggedUser(auth);
    } catch (e) {
      final msg = _extractAnyErrorMessage(
        e,
        codeOverrides: {'antofa_email_taken': 'El correo ya está registrado'},
      );
      state = state.copyWith(
        authStatus: AuthStatus.notAuthenticated,
        errorMessage: msg,
        errorSeq: state.errorSeq + 1,
      );
    }
  }

  // ======================
  // LOGIN
  // ======================
  Future<void> loginUser(String email, String password) async {
    try {
      state = state.copyWith(errorMessage: null);
      final auth = await authRepository.login(email, password);
      _setLoggedUser(auth);
    } catch (e) {
      final msg = _extractAnyErrorMessage(
        e,
        codeOverrides: {
          'antofa_invalid_credentials': 'Credenciales incorrectas',
        },
      );
      state = state.copyWith(
        authStatus: AuthStatus.notAuthenticated,
        errorMessage: msg,
        errorSeq: state.errorSeq + 1,
      );
    }
  }

  // ======================
  // FORGOT / RESET PASSWORD
  // ======================
  Future<void> sendRecoveryCode(String email) async {
    try {
      await authRepository.forgotPassword(email);
    } catch (e) {
      final msg = (e is DioException)
          ? _extractAnyErrorMessage(e)
          : 'No pudimos enviar el código';
      state = state.copyWith(errorMessage: msg);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final auth = await authRepository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      _setLoggedUser(auth);
    } catch (e) {
      final msg = (e is DioException)
          ? _extractAnyErrorMessage(e)
          : 'No se pudo cambiar la contraseña';
      state = state.copyWith(errorMessage: msg);
    }
  }

  // ======================
  // HELPERS
  // ======================
  String _extractAnyErrorMessage(
    Object e, {
    Map<String, String> codeOverrides = const {},
  }) {
    if (e is DioException) {
      final data = e.response?.data;
      Map<String, dynamic>? map;

      if (data is Map<String, dynamic>) {
        map = data;
      } else if (data is String) {
        try {
          map = Map<String, dynamic>.from(jsonDecode(data));
        } catch (_) {}
      }

      final code = map?['code'] as String?;
      final msg = map?['message'] as String?;

      if (code != null && codeOverrides.containsKey(code)) {
        return codeOverrides[code]!;
      }

      return msg ?? 'Ocurrió un error. Inténtalo nuevamente.';
    }

    try {
      final message = (e as dynamic).message as String?;
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {}

    return 'Ocurrió un error. Inténtalo nuevamente.';
  }

  void _setLoggedUser(Auth auth) async {
    await keyValueStorageService.setKeyValue<String>(
      'token',
      auth.session!.token,
    );

    if (auth.profile != null) {
      await keyValueStorageService.setKeyValue<String>(
        'email',
        auth.profile!.email,
      );
    }

    state = state.copyWith(
      authStatus: AuthStatus.authenticated,
      user: auth.profile,
      session: auth.session,
      errorMessage: '',
    );
  }

  Future<void> checkAuthStatus() async {
    final token = await keyValueStorageService.getValue<String>('token');
    if (token == null || token.isEmpty) {
      state = state.copyWith(authStatus: AuthStatus.notAuthenticated);
      return;
    }

    try {
      final CheckAuthStatus check = await authRepository.checkAuthStatus();
      if (check.data?.status == 200) {
        state = state.copyWith(authStatus: AuthStatus.authenticated);
      } else {
        await logoutUser();
      }
    } catch (_) {
      await logoutUser();
    }
  }

  Future<void> logoutUser([String? errorMessage]) async {
    await keyValueStorageService.removeKey('token');
    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage,
    );
  }
}
