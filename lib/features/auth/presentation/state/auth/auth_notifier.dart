import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';
import 'package:disfruta_antofagasta/features/auth/domain/repositories/auth_repository.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_state.dart';
import 'package:disfruta_antofagasta/shared/services/key_value_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  final KeyValueStorageService keyValueStorageService;

  AuthNotifier({
    required this.authRepository,
    required this.keyValueStorageService,
  }) : super(AuthState()) {
    checkAuthStatus();
  }

  // GUEST
  Future<void> guestUser(Guest guest) async {
    try {
      state = state.copyWith(errorMessage: null);

      final auth = await authRepository.guest(
        name: guest.name!,
        countryCode: guest.country!, // debe ser el code (CL/AR/PE)
        regionId: guest.region,
        age: guest.age,
        // 👇 IMPORTANTE: usar daysStay, que es lo que espera el repo/datasource
        daysStay: guest.day,
      );

      _setLoggedUser(auth!);
    } catch (e) {
      final msg = _extractAnyErrorMessage(e);
      state = state.copyWith(
        authStatus: AuthStatus.notAuthenticated,
        errorMessage: msg,
        errorSeq: state.errorSeq + 1, // 👈 igual que en login
      );
    }
  }

  // REGISTER
  Future<void> registerUser(RegisterUser req) async {
    try {
      state = state.copyWith(errorMessage: null);
      final auth = await authRepository.register(req);
      _setLoggedUser(auth);
    } catch (e) {
      final msg = _extractAnyErrorMessage(
        e,
        // mapeo del código del backend a un mensaje claro
        codeOverrides: {'antofa_email_taken': 'El correo ya está registrado'},
      );
      state = state.copyWith(
        authStatus: AuthStatus.notAuthenticated,
        errorMessage: msg,
        errorSeq: state.errorSeq + 1, // 👈 igual que en login
      );
    }
  }

  Future<void> loginUser(String email, String password) async {
    try {
      state = state.copyWith(errorMessage: null); // no toques errorSeq
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
        errorSeq: state.errorSeq + 1, // 👈 asegura SnackBar siempre
      );
    }
  }

  String _extractAnyErrorMessage(
    Object e, {
    Map<String, String> codeOverrides = const {},
  }) {
    // Caso A: DioException con response
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

      final status = e.response?.statusCode;
      final code = map?['code'] as String?;
      final msg = map?['message'] as String?;

      if (code != null && codeOverrides.containsKey(code)) {
        return codeOverrides[code]!;
      }
      if (status == 401 && (code == 'antofa_invalid_credentials')) {
        return msg ?? 'Credenciales incorrectas';
      }
      return msg ?? 'Ocurrió un error. Inténtalo nuevamente.';
    }

    // Caso B: algún CustomError propio con message
    try {
      // si tienes un CustomError con .message
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
      final isOk = check.data?.status == 200;
      if (isOk) {
        state = state.copyWith(
          authStatus: AuthStatus.authenticated,
          errorMessage: '',
        );
      } else {
        await logoutUser();
      }
      state = state.copyWith(authStatus: AuthStatus.authenticated);
    } catch (e) {
      logoutUser();
    }
  }

  Future<void> guestData([Guest? guest]) async {
    state = state.copyWith(guest: guest);
  }

  Future<void> logoutUser([String? errorMessage]) async {
    await keyValueStorageService.removeKey('token');
    state = state.copyWith(
      authStatus: AuthStatus.notAuthenticated,
      user: null,
      errorMessage: errorMessage,
    );
  }

  String _extractBackendMessage(
    DioException e, {
    Map<String, String>? codeOverrides,
    String fallback = 'Ocurrió un error. Inténtalo nuevamente.',
  }) {
    // Sin respuesta: errores de red / tiempo
    if (e.response == null) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Tiempo de espera agotado. Reintenta.';
        case DioExceptionType.connectionError:
          return 'Sin conexión. Verifica tu internet.';
        case DioExceptionType.cancel:
          return 'Solicitud cancelada.';
        default:
          return 'Error de red inesperado.';
      }
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;

    Map<String, dynamic>? json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is String) {
      try {
        json = Map<String, dynamic>.from(jsonDecode(data));
      } catch (_) {}
    }

    String? code;
    String? backendMessage;

    if (json != null) {
      code = json['code'] as String?;
      backendMessage = json['message'] as String?;

      // Soporta formato tipo { errors: { email: ["..."] } }
      final errors = json['errors'];
      if (errors is Map<String, dynamic>) {
        final joined = errors.values
            .expand((v) => v is List ? v : [v])
            .whereType<String>()
            .join('\n');
        if (joined.isNotEmpty) return joined;
      }
    }

    // Si tenemos un override para el code del backend, úsalo
    if (code != null && codeOverrides != null && codeOverrides[code] != null) {
      return codeOverrides[code]!;
    }

    // Mensaje del backend (si vino)
    if (backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    // Overrides por status comunes (fallbacks útiles)
    if (status == 401) return 'Credenciales incorrectas';
    if (status == 409) return 'Conflicto (409).';

    return fallback;
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> sendRecoveryCode(String email) async {
    try {
      await authRepository.forgotPassword(email);
      // No seteamos errorMessage; la UI ya cambia a paso 2 y puedes mostrar un SnackBar:
      // "Si el correo existe, te enviaremos un código"
    } catch (e) {
      final msg = (e is DioException)
          ? _extractBackendMessage(e)
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
      _setLoggedUser(auth); // 👈 éxito: quedas logueado
    } catch (e) {
      final msg = (e is DioException)
          ? _extractBackendMessage(e)
          : 'No se pudo cambiar la contraseña';
      state = state.copyWith(errorMessage: msg);
    }
  }
}
