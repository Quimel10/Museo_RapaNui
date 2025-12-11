import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_notifier.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_state.dart';
import 'package:disfruta_antofagasta/shared/session_manager.dart';
import 'package:disfruta_antofagasta/shared/session_flag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goRouterNotifierProvider = Provider<GoRouterNotifier>((ref) {
  final authNotifier = ref.read(authProvider.notifier);
  return GoRouterNotifier(authNotifier);
});

class GoRouterNotifier extends ChangeNotifier {
  final AuthNotifier _authNotifier;

  AuthStatus _authStatus = AuthStatus.checking;

  GoRouterNotifier(this._authNotifier) {
    _authNotifier.addListener((state) {
      // 1) Mantener la lógica original: actualizar authStatus y avisar al router
      authStatus = state.authStatus;

      // 2) Si el usuario está autenticado, marcamos sesión persistente
      if (state.authStatus == AuthStatus.authenticated) {
        // Marcamos el flag global para próximas aperturas
        SessionFlag.hasPersistedSession = true;

        // Guardamos algo no vacío para que loadSession() lo considere válido
        SessionManager.saveLoggedInSession(token: 'persisted');
      }

      // 👇 IMPORTANTE:
      // Ya NO borramos la sesión cuando pasa a notAuthenticated.
      // Eso evita que alguna verificación interna te "desloguee" sin querer.
      //
      // Si algún día quieres botón de Cerrar sesión, ahí sí llamás a:
      //   await SessionManager.clearSession();
      //   SessionFlag.hasPersistedSession = false;
    });
  }

  AuthStatus get authStatus => _authStatus;

  set authStatus(AuthStatus value) {
    _authStatus = value;
    notifyListeners();
  }
}
