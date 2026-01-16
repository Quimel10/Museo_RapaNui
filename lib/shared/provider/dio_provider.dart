import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart'; // ✅ keyValueStorageServiceProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _normalizeLang(String raw) {
  final v = raw.trim().toLowerCase().replaceAll('_', '-');
  if (v.isEmpty) return 'es';

  final base = v.split('-').first;

  const allowed = {'es', 'en', 'pt', 'fr', 'it', 'ja'};
  if (allowed.contains(base)) return base;
  if (base == 'jp') return 'ja';

  return 'es';
}

bool _isGeoCountriesRequest(RequestOptions ro) {
  final u = ro.uri.toString();
  return u.contains('/wp-json/app/v1/antofa/geo/countries');
}

Future<dynamic> _loadCountriesFallbackAsset() async {
  final raw = await rootBundle.loadString(
    'assets/data/countries_fallback.json',
  );
  return jsonDecode(raw); // normalmente List<dynamic>
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  final storage = ref.read(keyValueStorageServiceProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final langRaw = ref.read(languageProvider);
        final lang = _normalizeLang(langRaw);

        final qp = Map<String, dynamic>.from(options.queryParameters);
        qp['lang'] = lang;
        options.queryParameters = qp;

        options.headers['Accept-Language'] = lang;
        options.headers['X-App-Lang'] = lang;

        handler.next(options);
      },

      onResponse: (response, handler) async {
        try {
          if (_isGeoCountriesRequest(response.requestOptions)) {
            final lang =
                (response.requestOptions.queryParameters['lang'] ?? 'es')
                    .toString();
            final key = 'cache_geo_countries_$lang';

            final data = response.data;
            if (data is List) {
              await storage.setKeyValue(key, jsonEncode(data));
              // ignore: avoid_print
              print('✅ [DIO CACHE] saved $key (${data.length})');
            } else {
              // ignore: avoid_print
              print('⚠️ [DIO CACHE] countries payload is not List');
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ [DIO CACHE] save error: $e');
        }

        handler.next(response);
      },

      onError: (e, handler) async {
        // ✅ Offline fallback SOLO para countries
        try {
          if (_isGeoCountriesRequest(e.requestOptions)) {
            final lang = (e.requestOptions.queryParameters['lang'] ?? 'es')
                .toString();
            final key = 'cache_geo_countries_$lang';

            // 1) intenta cache
            final raw = await storage.getValue<String>(key);
            if (raw != null && raw.trim().isNotEmpty) {
              final decoded = jsonDecode(raw);

              // ignore: avoid_print
              print('🧩 [DIO CACHE] HIT $key (offline fallback)');

              return handler.resolve(
                Response(
                  requestOptions: e.requestOptions,
                  statusCode: 200,
                  data: decoded,
                ),
              );
            }

            // ignore: avoid_print
            print('! [DIO CACHE] MISS $key (no cached data)');

            // 2) si no hay cache, usa fallback asset (como "tipo visitante")
            try {
              final fallback = await _loadCountriesFallbackAsset();

              // ignore: avoid_print
              if (fallback is List) {
                print(
                  '🧩 [DIO FALLBACK] asset countries_fallback.json => ${fallback.length}',
                );
              } else {
                print('🧩 [DIO FALLBACK] asset countries_fallback.json loaded');
              }

              return handler.resolve(
                Response(
                  requestOptions: e.requestOptions,
                  statusCode: 200,
                  data: fallback,
                ),
              );
            } catch (assetErr) {
              // ignore: avoid_print
              print('❌ [DIO FALLBACK] asset error: $assetErr');
            }
          }
        } catch (err) {
          // ignore: avoid_print
          print('⚠️ [DIO CACHE] onError handler failed: $err');
        }

        handler.next(e);
      },
    ),
  );

  return dio;
});
