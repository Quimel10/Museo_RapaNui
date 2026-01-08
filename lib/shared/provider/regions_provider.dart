// lib/shared/provider/regions_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_provider.dart';

class Region {
  final int id;
  final int countryId;
  final String code;
  final String name;
  final bool active;

  const Region({
    required this.id,
    required this.countryId,
    required this.code,
    required this.name,
    required this.active,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: _asInt(json['id']),
      countryId: _asInt(json['country_id']),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      active: _asBool(json['active']),
    );
  }
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

bool _asBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().trim();
  return s == '1' || s.toLowerCase() == 'true';
}

/// ✅ Devuelve regiones por countryCode (ej: "CL").
/// - Si countryCode es null/empty: devuelve []
/// - Orden: activas primero, luego alfabético
final regionsProvider = FutureProvider.autoDispose
    .family<List<Region>, String?>((ref, countryCode) async {
      final dio = ref.watch(dioProvider);

      final code = (countryCode ?? '').trim().toUpperCase();
      if (code.isEmpty) return const [];

      try {
        // OJO: tu dioProvider ya inyecta ?lang=xx automáticamente
        // así que acá solo enviamos el country.
        final resp = await dio.get(
          '/wp-json/app/v1/geo_regions',
          queryParameters: {'country': code},
        );

        final data = resp.data;

        if (data is! List) return const [];

        final items = data
            .whereType<Map>()
            .map((e) => Region.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        items.sort((a, b) {
          final byActive = (b.active ? 1 : 0) - (a.active ? 1 : 0);
          if (byActive != 0) return byActive;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        return items;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final path = e.requestOptions.path;
        throw Exception('Error Dio en $path (status: $status): ${e.message}');
      }
    });
