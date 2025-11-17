import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';

class GuestMapper {
  static Guest jsonToEnitity(Map<String, dynamic> json) => Guest(
    name: json["name"],
    id: json["id"],
    country: json["country"],
    region: json["region"],
  );
}
