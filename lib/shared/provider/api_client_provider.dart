// lib/shared/provider/api_client_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart';
import 'package:disfruta_antofagasta/shared/services/analitics_tracker.dart';

/// ApiClient mínimo: usa el Dio ya configurado (baseUrl, headers, interceptors, etc.)
class ApiClient {
  final Dio dio;
  ApiClient(this.dio);

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }
}

/// ✅ Provider global del ApiClient (esto es lo que te faltaba)
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

/// ✅ Provider global para el tracker de analíticas (lo tuyo queda intacto)
final analyticsProvider = Provider<AnalyticsTracker>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(keyValueStorageServiceProvider);

  return AnalyticsTracker(ref: ref, dio: dio, storage: storage);
});
