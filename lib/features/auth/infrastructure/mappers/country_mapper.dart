import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';

class CountryMapper {
  static int _stableIdFromCode(String code) {
    // id estable simple (sin depender de backend)
    // hashCode NO es estable entre ejecuciones => evitamos.
    // Usamos suma de codeUnits (suficiente para fallback).
    final up = code.trim().toUpperCase();
    if (up.isEmpty) return 1;
    var sum = 0;
    for (final u in up.codeUnits) {
      sum = (sum * 31 + u) & 0x7fffffff;
    }
    return sum == 0 ? 1 : sum;
  }

  static Country jsonToEnitity(Map<String, dynamic> json) {
    final code = (json['code'] ?? '').toString().trim();
    final name = (json['name'] ?? code).toString();

    final rawId = json['id'];
    final id = int.tryParse(rawId?.toString() ?? '') ?? _stableIdFromCode(code);

    final activeRaw = json['active'];
    final active = activeRaw == null
        ? true
        : (activeRaw.toString() == '1' ||
              activeRaw.toString().toLowerCase() == 'true');

    final rcRaw = json['regions_count'];
    final regionsCount = int.tryParse(rcRaw?.toString() ?? '') ?? 0;

    return Country(
      id: id,
      code: code,
      name: name,
      active: active,
      regionsCount: regionsCount,
    );
  }
}
