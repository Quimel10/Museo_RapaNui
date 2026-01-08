import 'package:disfruta_antofagasta/features/auth/domain/entities/session.dart';

class SessionMapper {
  // compatibilidad con el nombre viejo
  static Session jsonToEnitity(Map<String, dynamic> json) => jsonToEntity(json);

  static Session jsonToEntity(Map<String, dynamic> json) => Session(
    token: (json['token'] ?? '').toString(),
    type: (json['type'] ?? 'bearer').toString(),

    // ✅ algunos backends mandan user_id, otros userId
    userId: _toInt(json['user_id'] ?? json['userId'] ?? json['id']),

    // ✅ tu entity exige guestId sí o sí (aunque sea 0 en login/register)
    guestId: _toInt(json['guest_id'] ?? json['guestId']),
  );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
