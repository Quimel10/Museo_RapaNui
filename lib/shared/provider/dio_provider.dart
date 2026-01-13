import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
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

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // ✅ Normaliza SIEMPRE (evita es-AR / en-US / es-419 rompiendo WP)
        final langRaw = ref.read(languageProvider);
        final lang = _normalizeLang(langRaw);

        // ✅ Forzar query param lang (sin duplicarlo mal)
        final qp = Map<String, dynamic>.from(options.queryParameters);
        qp['lang'] = lang;
        options.queryParameters = qp;

        // ✅ Headers robustos para WP / Polylang
        options.headers['Accept-Language'] = lang;
        options.headers['X-App-Lang'] = lang;

        handler.next(options);
      },
    ),
  );

  return dio;
});
