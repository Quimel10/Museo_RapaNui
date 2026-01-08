// lib/shared/provider/countries_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_provider.dart';

/// Modelo simple para País.
/// Se mapea 1:1 con tu endpoint:
/// /wp-json/app/v1/geo_countries?lang=es
///
/// Ejemplo de respuesta (según tu captura):
/// [{
///   "id": 2734821342,
///   "code": "AR",
///   "name": "Argentina",
///   "active": 1,
///   "regions_count": 2
/// }, ...]
class Country {
  final int id;
  final String code;
  final String name;
  final bool active;
  final int regionsCount;

  const Country({
    required this.id,
    required this.code,
    required this.name,
    required this.active,
    required this.regionsCount,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    bool parseBool01(dynamic v, {bool fallback = false}) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == '1' || s == 'true' || s == 'yes') return true;
        if (s == '0' || s == 'false' || s == 'no') return false;
      }
      return fallback;
    }

    return Country(
      id: parseInt(json['id']),
      code: (json['code'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      active: parseBool01(json['active'], fallback: true),
      regionsCount: parseInt(json['regions_count']),
    );
  }
}

/// Provider que trae la lista de países desde WP.
/// Usa el `dioProvider` que ya inyecta `lang` automáticamente.
final countriesProvider = FutureProvider.autoDispose<List<Country>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);

  try {
    final resp = await dio.get('/wp-json/app/v1/geo_countries');

    final data = resp.data;
    if (data is! List) {
      throw StateError(
        'Respuesta inesperada en /geo_countries (se esperaba List). Recibido: ${data.runtimeType}',
      );
    }

    final items = data
        .whereType<Map>()
        .map((m) => Country.fromJson(Map<String, dynamic>.from(m)))
        .where((c) => c.code.isNotEmpty && c.name.isNotEmpty)
        .toList();

    // Orden: activos primero, luego alfabético por nombre.
    items.sort((a, b) {
      final byActive = (b.active ? 1 : 0) - (a.active ? 1 : 0);
      if (byActive != 0) return byActive;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  } on DioException catch (e) {
    // Mensaje más claro para debug
    final status = e.response?.statusCode;
    final path = e.requestOptions.path;
    throw Exception('Error Dio en $path (status: $status): ${e.message}');
  }
});
