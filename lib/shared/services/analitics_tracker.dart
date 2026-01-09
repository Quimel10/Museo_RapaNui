// lib/shared/services/analitics_tracker.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/shared/services/key_value_storage_service.dart';

class AnalyticsTracker {
  AnalyticsTracker({
    required this.ref,
    required this.dio,
    required this.storage,
  });

  final Ref ref;
  final Dio dio;
  final KeyValueStorageService storage;

  Future<void> track({
    required String eventName,
    required String objectType,
    required String objectId,
    Map<String, dynamic>? meta,
  }) async {
    final tok = await storage.getValue<String>('token');
    final lang = await storage.getValue<String>('language') ?? 'es';

    // ✅ FIX: substring seguro (evita RangeError si token < 10)
    final tokenPreview = (tok == null || tok.isEmpty)
        ? 'NULL'
        : (tok.length <= 10 ? tok : tok.substring(0, 10));

    print('[ANALYTICS] token: $tokenPreview...');

    final payload = <String, dynamic>{
      'lang': lang,
      'event_name': eventName,
      'object_type': objectType,
      'object_id': objectId,
      'meta': {'ts': DateTime.now().toIso8601String(), ...?meta},
    };

    print('[ANALYTICS] Enviando payload: $payload');

    // ✅ FIX: fallback de endpoint (por si tu API real es /events)
    final endpoints = <String>['/antofa/events', '/events'];

    DioException? lastErr;

    for (final path in endpoints) {
      try {
        final response = await dio.post(
          path,
          data: payload,
          options: (tok != null && tok.isNotEmpty)
              ? Options(headers: {'Authorization': 'Bearer $tok'})
              : null,
        );

        print(
          '[ANALYTICS] OK ($path) status: ${response.statusCode} data: ${response.data}',
        );
        return; // ✅ listo
      } on DioException catch (e) {
        lastErr = e;

        final code = e.response?.statusCode;
        print('[ANALYTICS] FAIL ($path) status: $code error: ${e.message}');

        // Si no es 404, no tiene sentido seguir probando (ej: 401, 500, etc.)
        if (code != 404) break;
      } catch (e) {
        print('[ANALYTICS] ERROR ($path): $e');
        break;
      }
    }

    // Si llegó acá, falló todo
    if (lastErr != null) {
      print(
        '[ANALYTICS] FINAL ERROR: ${lastErr.response?.statusCode} ${lastErr.message}',
      );
    }
  }

  void clickCategory(int id, {Map<String, dynamic>? meta}) => track(
    eventName: 'click',
    objectType: 'category',
    objectId: '$id',
    meta: meta,
  );

  void clickBanner(int id, {Map<String, dynamic>? meta}) => track(
    eventName: 'click',
    objectType: 'banner',
    objectId: '$id',
    meta: meta,
  );

  void clickObject(int id, {Map<String, dynamic>? meta}) => track(
    eventName: 'click',
    objectType: 'point',
    objectId: '$id',
    meta: meta,
  );
}
