// lib/features/auth/domain/entities/guest.dart
class Guest {
  final int? id;

  /// Datos del formulario / backend
  final String? name;
  final String? countryCode; // "CL", "AR", etc.
  final int? regionId; // id numérico
  final int? age;
  final int? daysStay; // días de visita

  /// 'rapanui' | 'continental' | 'foreign'
  final String? visitorType;

  const Guest({
    this.id,
    this.name,
    this.countryCode,
    this.regionId,
    this.age,
    this.daysStay,
    this.visitorType,
  });

  Guest copyWith({
    int? id,
    String? name,
    String? countryCode,
    int? regionId,
    int? age,
    int? daysStay,
    String? visitorType,
  }) {
    return Guest(
      id: id ?? this.id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      regionId: regionId ?? this.regionId,
      age: age ?? this.age,
      daysStay: daysStay ?? this.daysStay,
      visitorType: visitorType ?? this.visitorType,
    );
  }

  /// ✅ Para llamadas que quieran serializar el guest
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': (name ?? '').trim(),
    'country_code': (countryCode ?? '').trim(),
    'region_id': regionId,
    'age': age,
    'days_stay': daysStay,
    'visitor_type': (visitorType ?? '').trim(), // ✅ CLAVE
  };
}
