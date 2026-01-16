// lib/shared/utils/network_error.dart
import 'dart:io';

class NetworkError {
  /// Detecta errores típicos de conectividad: sin internet, DNS, timeout, socket.
  static bool isOffline(Object e) {
    // Dio (si lo usas) a veces envuelve en un tipo propio, pero igual trae mensajes comunes.
    final msg = e.toString().toLowerCase();

    // Errores típicos
    if (e is SocketException) return true;
    if (e is HttpException) return true;
    if (e is HandshakeException) return true;

    // Timeout (si viene como string)
    if (msg.contains('timed out') || msg.contains('timeout')) return true;

    // DNS / host lookup
    if (msg.contains('failed host lookup') ||
        msg.contains('name not resolved') ||
        msg.contains('nodename nor servname provided') ||
        msg.contains('temporary failure in name resolution')) {
      return true;
    }

    // Sin conexión
    if (msg.contains('network is unreachable') ||
        msg.contains('no internet') ||
        msg.contains('connection failed') ||
        msg.contains('socketexception')) {
      return true;
    }

    return false;
  }

  /// Mensaje bonito para el usuario (Museo).
  static String userMessage(Object e, {String fallback = 'Ocurrió un error.'}) {
    if (isOffline(e)) {
      return 'Sin conexión.\nRevisa tu señal o Wi-Fi e inténtalo nuevamente.';
    }
    return fallback;
  }
}
