import 'package:disfruta_antofagasta/features/auth/domain/entities/user.dart';

class UserMapper {
  // Mantengo ambos nombres para compatibilidad
  static User jsonToEnitity(Map<String, dynamic> json) => jsonToEntity(json);

  static User jsonToEntity(Map<String, dynamic> json) => User(
    id: _toInt(json['id']),
    name: (json['name'] ?? '').toString(),
    lastname: (json['lastname'] ?? json['last_name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    countryCode: (json['country_code'] ?? json['countryCode'] ?? '').toString(),
  );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}
