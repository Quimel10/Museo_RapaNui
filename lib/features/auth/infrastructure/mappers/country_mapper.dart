import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';

class CountryMapper {
  static Country jsonToEnitity(Map<String, dynamic> json) => Country(
    id: int.parse(json['id'].toString()),
    code: json['code'],
    name: json['name'],
    active: json['active'].toString() == '1',
    regionsCount: int.parse(json['regions_count'].toString()),
  );
}
