import 'package:disfruta_antofagasta/features/auth/domain/entities/session.dart';

class SessionMapper {
  static Session jsonToEnitity(Map<String, dynamic> json) => Session(
    token: json["token"],
    type: json["type"],
    userId: json["user_id"],
    guestId: json["guest_id"],
    expiresAt: DateTime.parse(json['expires_at'] as String),
  );
}
