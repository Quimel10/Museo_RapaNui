import 'package:disfruta_antofagasta/features/auth/domain/entities/user.dart';

class UserMapper {
  static User jsonToEnitity(Map<String, dynamic> json) => User(
    name: json["name"],
    id: json["id"],
    email: json["email"],
    lastname: json["lastname"],
    countryCode: json['country_code'],
    countryName: json['country_name'],
    regionName: json['region_name'],
    regionId: json['region_id'],
    daysStay: json['days_stay'],
    arrivalDate: json['arrival_date'],
    departureDate: json['departure_date'],
    age: json['age'],
  );
}
