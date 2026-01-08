class RegisterUser {
  final String name;
  final String lastname;
  final String email;
  final String password;
  final String countryCode;
  final int? regionId;
  final int? age;
  final int? daysStay;

  /// rapanui | continental | foreign
  final String visitorType;

  final DateTime? arrivalDate;
  final DateTime? departureDate;
  final String? device;

  RegisterUser({
    required this.name,
    required this.lastname,
    required this.email,
    required this.password,
    required this.countryCode,
    required this.visitorType,
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
      'visitor_type': visitorType,
      'arrival_date': arrivalDate?.toIso8601String(),
      'departure_date': departureDate?.toIso8601String(),
      'device': device,
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }
}
