// lib/features/auth/domain/entities/register_user.dart
class RegisterUser {
  final String name;
  final String lastname;
  final String email;
  final String password;
  final String countryCode; // "CL"
  final int? regionId; // 3
  final int? age; // null o número
  final int? daysStay; // null o número
  final DateTime? arrivalDate; // null o fecha
  final DateTime? departureDate; // null o fecha
  final String? device; // "android:pixel7"

  RegisterUser({
    required this.name,
    required this.lastname,
    required this.email,
    required this.password,
    required this.countryCode,
    this.regionId,
    this.age,
    this.daysStay,
    this.arrivalDate,
    this.departureDate,
    this.device,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'name': name,
      'lastname': lastname,
      'email': email,
      'password': password,
      'country_code': countryCode,
      'region_id': regionId,
      'age': age,
      'days_stay': daysStay,
      'arrival_date': arrivalDate?.toIso8601String(),
      'departure_date': departureDate?.toIso8601String(),
      'device': device,
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }
}
