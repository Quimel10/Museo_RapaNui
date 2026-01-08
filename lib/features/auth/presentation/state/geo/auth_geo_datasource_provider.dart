import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/shared/provider/api_client_provider.dart';

class AuthGeoDataSource {
  final ApiClient api;

  static const String _base =
      'https://sitio1.unbcorp.cl/ant_q/wp-json/app/v1/antofa/geo';

  AuthGeoDataSource(this.api);

  Future<List<Country>> countries() async {
    try {
      final url = '$_base/countries';
      // ignore: avoid_print
      print('🌍 GET geo/countries => $url');

      final resp = await api.get(url);

      final data = resp.data;
      final list = (data is Map && data['countries'] is List)
          ? (data['countries'] as List)
          : (data is List ? data : const []);

      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map<Country>((m) {
            return Country(
              id: _toInt(m['id']),
              code: (m['code'] ?? '').toString(),
              name: (m['name'] ?? '').toString(),
              active: _toBool(m['active'], fallback: true),
              regionsCount: _toInt(m['regions_count']),
            );
          })
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ countries error: $e');
      return <Country>[];
    }
  }

  Future<List<Region>> regionsByCountryCode(String countryCode) async {
    try {
      final cc = countryCode.trim().toUpperCase();
      final url = '$_base/regions';
      // ignore: avoid_print
      print('🌍 GET geo/regions => $url ($cc)');

      final resp = await api.get(url, queryParameters: {'country_code': cc});

      final data = resp.data;
      final list = (data is Map && data['regions'] is List)
          ? (data['regions'] as List)
          : (data is List ? data : const []);

      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map<Region>((m) {
            return Region(
              id: _toInt(m['id']),
              countryId: _toInt(m['country_id']),
              code: (m['code'] ?? '').toString(),
              name: (m['name'] ?? '').toString(),
              active: _toBool(m['active'], fallback: true),
            );
          })
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('❌ regions error: $e');
      return <Region>[];
    }
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  bool _toBool(dynamic v, {required bool fallback}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == '1' || s == 'true') return true;
    if (s == '0' || s == 'false') return false;
    return fallback;
  }
}

final authGeoDataSourceProvider = Provider<AuthGeoDataSource>((ref) {
  final api = ref.read(apiClientProvider);
  return AuthGeoDataSource(api);
});
