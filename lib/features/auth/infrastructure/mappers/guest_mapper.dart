import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';

class GuestMapper {
  // Mantengo ambos nombres para que no rompa AuthMapper viejo
  static Guest jsonToEnitity(Map<String, dynamic> json) => jsonToEntity(json);

  static Guest jsonToEntity(Map<String, dynamic> json) => Guest(
    id: _toInt(json['id']),
    name: (json['name'] ?? '').toString(),
    countryCode: (json['country_code'] ?? json['countryCode'] ?? '').toString(),
    visitorType: (json['visitor_type'] ?? json['visitorType'] ?? '').toString(),
    regionId: _toIntNullable(json['region_id'] ?? json['regionId']),
    age: _toIntNullable(json['age']),
    daysStay: _toIntNullable(json['days_stay'] ?? json['daysStay']),
  );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static int? _toIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
