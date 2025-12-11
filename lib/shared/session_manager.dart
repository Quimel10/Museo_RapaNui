import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyIsGuest = 'is_guest';
  static const _keyToken =
      'auth_token'; // si usas token, si no, puedes ignorarlo

  /// Guardar sesión como usuario normal
  static Future<void> saveLoggedInSession({required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setBool(_keyIsGuest, false);
    await prefs.setString(_keyToken, token);
  }

  /// Guardar sesión como invitado
  static Future<void> saveGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.setBool(_keyIsGuest, true);
    await prefs.remove(_keyToken);
  }

  /// Limpiar sesión (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyIsGuest);
    await prefs.remove(_keyToken);
  }

  /// Leer estado guardado al iniciar la app
  static Future<SessionState> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final isGuest = prefs.getBool(_keyIsGuest) ?? false;
    final token = prefs.getString(_keyToken);

    if (isLoggedIn && token != null && token.isNotEmpty) {
      return SessionState.loggedIn(token: token);
    } else if (isGuest) {
      return SessionState.guest();
    } else {
      return SessionState.loggedOut();
    }
  }
}

class SessionState {
  final bool isLoggedIn;
  final bool isGuest;
  final String? token;

  SessionState._({required this.isLoggedIn, required this.isGuest, this.token});

  factory SessionState.loggedIn({required String token}) =>
      SessionState._(isLoggedIn: true, isGuest: false, token: token);

  factory SessionState.guest() =>
      SessionState._(isLoggedIn: false, isGuest: true);

  factory SessionState.loggedOut() =>
      SessionState._(isLoggedIn: false, isGuest: false);
}

extension SessionStateX on SessionState {
  bool get hasSession => isLoggedIn || isGuest;
}
