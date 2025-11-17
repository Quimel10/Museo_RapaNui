class User {
  final int? id;
  final String name;
  final String lastname;
  final String email;
  final String countryCode;
  final String? countryName;
  final String? regionName;
  final int? regionId;
  final int? daysStay;
  final int? age;

  final String? divice;
  final String? arrivalDate;
  final String? departureDate;

  User({
    required this.name,
    required this.lastname,
    required this.email,
    required this.countryCode,
    this.regionId,
    this.id,
    this.daysStay,
    this.divice,
    this.countryName,
    this.regionName,
    this.arrivalDate,
    this.departureDate,
    this.age,
  });
}
