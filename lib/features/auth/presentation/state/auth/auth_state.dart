import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/session.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/user.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState {
  final AuthStatus authStatus;
  final User? user;
  final Session? session;
  final Guest? guest;

  /// ✅ Nullable porque lo usas como null para "sin error"
  final String? errorMessage;

  /// Útil para forzar SnackBars aunque el mensaje sea igual
  final int errorSeq;

  AuthState({
    this.authStatus = AuthStatus.checking,
    this.user,
    this.session,
    this.guest,
    this.errorMessage,
    this.errorSeq = 0,
  });

  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    Session? session,
    Guest? guest,
    String? errorMessage,
    int? errorSeq,
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    session: session ?? this.session,
    guest: guest ?? this.guest,
    errorMessage: errorMessage,
    errorSeq: errorSeq ?? this.errorSeq,
  );
}
