import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/mappers/country_mapper.dart';
import 'package:disfruta_antofagasta/shared/services/key_value_storage_service.dart';

class OfflineGeoCache {
  final KeyValueStorageService storage;

  OfflineGeoCache(this.storage);

  static const _countriesCacheKeyPrefix = 'cache_geo_countries_';

  String _keyCountries(String lang) => '$_countriesCacheKeyPrefix$lang';

  Future<List<Country>> readCountriesCache(String lang) async {
    final raw = await storage.getValue<String>(_keyCountries(lang));
    if (raw == null || raw.trim().isEmpty) return <Country>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Country>[];

      return decoded
          .cast<Map<String, dynamic>>()
          .map(CountryMapper.jsonToEnitity)
          .where((c) => c.active)
          .toList();
    } catch (_) {
      return <Country>[];
    }
  }

  Future<void> saveCountriesRaw(String lang, List<dynamic> rawList) async {
    // guardamos RAW tal cual viene del endpoint (List)
    try {
      await storage.setKeyValue(_keyCountries(lang), jsonEncode(rawList));
    } catch (_) {}
  }

  Future<List<Country>> readCountriesFallback() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/countries_fallback.json',
      );
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Country>[];

      return decoded
          .cast<Map<String, dynamic>>()
          .map(CountryMapper.jsonToEnitity)
          .where((c) => c.active)
          .toList();
    } catch (_) {
      return <Country>[];
    }
  }
}
