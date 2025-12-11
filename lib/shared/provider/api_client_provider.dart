// lib/shared/provider/api_client_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart';
import 'package:disfruta_antofagasta/shared/services/analitics_tracker.dart';

/// Provider global para el tracker de analíticas.
final analyticsProvider = Provider<AnalyticsTracker>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(keyValueStorageServiceProvider);

  return AnalyticsTracker(ref: ref, dio: dio, storage: storage);
});
