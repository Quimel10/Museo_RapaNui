import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/session.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/user.dart';

enum AuthStatus { checking, authenticated, notAuthenticated }

class AuthState {
  final AuthStatus authStatus;
  final User? user;
  final Session? session;
  final Guest? guest;
  final String errorMessage;
  final int errorSeq;
  AuthState({
    this.authStatus = AuthStatus.checking,
    this.user,
    this.session,
    this.guest,
    this.errorMessage = '',
    this.errorSeq = 0,
  });
  AuthState copyWith({
    AuthStatus? authStatus,
    User? user,
    Session? session,
    Guest? guest,
    String? errorMessage,
    int? errorSeq,

    String? token,
  }) => AuthState(
    authStatus: authStatus ?? this.authStatus,
    user: user ?? this.user,
    guest: guest ?? this.guest,
    errorMessage: errorMessage ?? this.errorMessage,
    session: session ?? this.session,
    errorSeq: errorSeq ?? this.errorSeq,
  );
}
