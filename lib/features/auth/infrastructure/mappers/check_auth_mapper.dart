import 'package:disfruta_antofagasta/features/auth/domain/entities/check_auth.dart';

class CheckAuthMapper {
  static CheckAuthStatus checkJsonToEntity(Map<String, dynamic> json) =>
      CheckAuthStatus(
        data: json["data"] != null ? dataJsonToEntity(json["data"]) : null,
        message: json["message"],
      );

  static Data dataJsonToEntity(Map<String, dynamic> json) =>
      Data(status: json["status"]);
}
