// lib/shared/provider/api_client_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';

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

bool _isAvailableLanguagesRequest(RequestOptions ro) {
  final u = ro.uri.toString();
  return u.contains('/wp-json/app/v1/available_languages');
}

void _applyBrowserLikeHeaders(RequestOptions options) {
  // Limpia headers que suelen gatillar WAF
  options.headers.remove('Accept-Language');
  options.headers.remove('X-App-Lang');
  options.headers.remove('Cache-Control');
  options.headers.remove('Pragma');
  options.headers.remove('Expires');

  // Headers mínimos tipo navegador
  options.headers['Accept'] = 'application/json';
  options.headers['User-Agent'] =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
}

/// ✅ Wrapper ApiClient (para que tu app siga compilando)
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl, // ej: https://sitio1.../wp-json/app/v1
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final qp = Map<String, dynamic>.from(options.queryParameters);

        // ✅ Permite saltar lang por request
        final skipLang = options.extra['skip_lang'] == true;

        if (!skipLang) {
          final langRaw = ref.read(languageProvider);
          final lang = _normalizeLang(langRaw);

          qp.putIfAbsent('lang', () => lang);
          options.queryParameters = qp;

          // headers app para el resto (si tu WAF es sensible, quítalos global)
          options.headers['Accept-Language'] = qp['lang'];
          options.headers['X-App-Lang'] = qp['lang'];
        } else {
          // ✅ no lang / no headers app
          qp.remove('lang');
          options.queryParameters = qp;
          options.headers.remove('Accept-Language');
          options.headers.remove('X-App-Lang');
        }

        // ✅ Endpoint especial: available_languages (WAF)
        if (_isAvailableLanguagesRequest(options)) {
          _applyBrowserLikeHeaders(options);
          // Seguridad extra: fuera cache headers
          options.headers.remove('Cache-Control');
          options.headers.remove('Pragma');
        }

        handler.next(options);
      },
    ),
  );

  return ApiClient(dio);
});
