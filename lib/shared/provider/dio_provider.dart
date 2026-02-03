import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart'; // keyValueStorageServiceProvider

String _normalizeLang(String raw) {
  final v = raw.trim().toLowerCase().replaceAll('_', '-');
  if (v.isEmpty) return 'es';

  final base = v.split('-').first;

  // ✅ idioma estándar: ja (no jp)
  const allowed = {'es', 'en', 'pt', 'fr', 'it', 'ja'};
  if (allowed.contains(base)) return base;
  if (base == 'jp') return 'ja';

  return 'es';
}

bool _isGeoCountriesRequest(RequestOptions ro) {
  final u = ro.uri.toString();
  return u.contains('/wp-json/app/v1/antofa/geo/countries');
}

bool _isAvailableLanguagesRequest(RequestOptions ro) {
  final u = ro.uri.toString();
  return u.contains('/wp-json/app/v1/available_languages');
}

Future<dynamic> _loadCountriesFallbackAsset() async {
  final raw = await rootBundle.loadString(
    'assets/data/countries_fallback.json',
  );
  return jsonDecode(raw);
}

void _applyBrowserLikeHeaders(RequestOptions options) {
  // ✅ Limpia headers que suelen gatillar WAF
  options.headers.remove('Accept-Language');
  options.headers.remove('X-App-Lang');
  options.headers.remove('Cache-Control');
  options.headers.remove('Pragma');
  options.headers.remove('Expires');

  // ✅ Deja headers mínimos tipo navegador
  options.headers['Accept'] = 'application/json';
  options.headers['User-Agent'] =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl, // ej: https://sitio1.../wp-json/app/v1
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        // ⚠️ No pongas un UA “FlutterApp” global: eso lo huelen los WAF.
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      },
    ),
  );

  final storage = ref.read(keyValueStorageServiceProvider);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // ✅ Flag para saltar inyección de lang en endpoints sensibles
        final skipLang = options.extra['skip_lang'] == true;

        // ✅ Copia segura de query params
        final qp = Map<String, dynamic>.from(options.queryParameters);

        if (!skipLang) {
          // ✅ Siempre agrega lang, respetando query params existentes
          final langRaw = ref.read(languageProvider);
          final lang = _normalizeLang(langRaw);
          qp.putIfAbsent('lang', () => lang);
        } else {
          // Si viene lang por error, lo limpiamos para evitar 403 por WAF
          qp.remove('lang');
        }

        options.queryParameters = qp;

        // ✅ Caso especial: available_languages (WAF 403)
        if (_isAvailableLanguagesRequest(options)) {
          _applyBrowserLikeHeaders(options);

          // ✅ además: evita que alguien te meta no-cache
          options.headers.remove('Cache-Control');
          options.headers.remove('Pragma');
        } else {
          // ✅ Para el resto, headers de idioma solo si NO estamos en skipLang
          if (!skipLang) {
            final langHeader = (qp['lang'] ?? 'es').toString();
            options.headers['Accept-Language'] = langHeader;
            options.headers['X-App-Lang'] = langHeader;
          } else {
            options.headers.remove('Accept-Language');
            options.headers.remove('X-App-Lang');
          }
        }

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

            try {
              final fallback = await _loadCountriesFallbackAsset();
              // ignore: avoid_print
              print('🧩 [DIO FALLBACK] asset countries_fallback.json loaded');

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
