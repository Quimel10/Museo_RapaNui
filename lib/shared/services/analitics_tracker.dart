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

    // ⬇️ LOG del token (solo primeros 10 chars para no mostrar todo)
    print(
      '[ANALYTICS] token: ${tok == null ? 'NULL' : tok.substring(0, 10)}...',
    );

    final payload = <String, dynamic>{
      'lang': lang,
      'event_name': eventName,
      'object_type': objectType,
      'object_id': objectId,
      'meta': {'ts': DateTime.now().toIso8601String(), ...?meta},
    };

    print('[ANALYTICS] Enviando payload: $payload');

    try {
      final response = await dio.post(
        '/antofa/events',
        data: payload,
        options: tok != null && tok.isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer $tok'})
            : null,
      );

      print(
        '[ANALYTICS] OK status: ${response.statusCode} data: ${response.data}',
      );
    } catch (e) {
      print('[ANALYTICS] ERROR: $e');
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
