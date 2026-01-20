// lib/features/auth/domain/entities/register_user.dart

class RegisterUser {
  final String name;
  final String lastname;
  final String email;
  final String password;
  final String countryCode;
  final int? regionId;
  final int? age;
  final int? daysStay;

  /// ✅ visitorType debe viajar como KEY canónico:
  /// - local_rapanui
  /// - local_no_rapanui
  /// - continental
  /// - extranjero
  ///
  /// (igual aceptamos compat: rapanui / foreign / textos viejos)
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

  /// ✅ Normaliza a keys canónicos antes de serializar.
  static String _normalizeVisitorTypeKey(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return 'continental';

    // canónicos
    if (v == 'local_rapanui' ||
        v == 'local_no_rapanui' ||
        v == 'continental' ||
        v == 'extranjero') {
      return v;
    }

    // compat antiguos app
    if (v == 'rapanui') return 'local_rapanui';
    if (v == 'foreign') return 'extranjero';

    // compat textos
    if (v.contains('no rapanui') || v.contains('no-rapanui')) {
      return 'local_no_rapanui';
    }
    if (v.contains('rapanui')) return 'local_rapanui';
    if (v.contains('continental')) return 'continental';
    if (v.contains('extranj') || v.contains('visitante')) return 'extranjero';

    return 'continental';
  }

  Map<String, dynamic> toJson() {
    final normalizedVisitorType = _normalizeVisitorTypeKey(visitorType);

    final m = <String, dynamic>{
      'name': name.trim(),
      'lastname': lastname.trim(),
      'email': email.trim(),
      'password': password,
      'country_code': countryCode.trim().toUpperCase(),
      'region_id': regionId,
      'age': age,
      'days_stay': daysStay,
      'visitor_type': normalizedVisitorType,
      'arrival_date': arrivalDate?.toIso8601String(),
      'departure_date': departureDate?.toIso8601String(),
      'device': device,
    };

    m.removeWhere((_, v) => v == null);
    return m;
  }
}
