import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

class RegionMapper {
  static Region jsonToEnitity(Map<String, dynamic> json) => Region(
    id: int.parse(json['id'].toString()),
    countryId: int.parse(json['country_id'].toString()),
    code: json['code'],
    name: json['name'],
    active: json['active'].toString() == '1',
  );
}
