import 'dart:async' show unawaited, scheduleMicrotask;
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
    // Siempre desde storage
    final tok = await storage.getValue<String>('token'); // o 'token'
    final lang = await storage.getValue<String>('language'); // o 'token'
    if (tok == null || tok.isEmpty) {
      return; // sin token -> no enviamos
    }

    final payload = {
      'lang': lang,
      'event_name': eventName,
      'object_type': objectType,
      'object_id': objectId,
      'meta': {'ts': DateTime.now().toIso8601String(), ...?meta},
    };

    // fire-and-forget
    scheduleMicrotask(() async {
      print(payload);
      try {
        await dio.post(
          '/antofa/events',
          data: payload,
          options: Options(headers: {'Authorization': 'Bearer $tok'}),
        );
      } catch (e) {
        print('error: $e');
        // opcional: debugPrint('analytics error: $e');
        // ignoramos para no romper la UI
      }
    });
  }

  // Helpers
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
