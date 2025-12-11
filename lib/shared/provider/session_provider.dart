import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/shared/session_manager.dart';

/// Este provider mantiene el estado de sesión cargado desde main.dart
/// (usuario logeado, invitado, o sin sesión).
///
/// En main.dart lo sobreescribimos con `overrideWithValue(session)`.
final sessionStateProvider = Provider<SessionState>((ref) {
  return SessionState.loggedOut(); // default si no se sobreescribe
});
