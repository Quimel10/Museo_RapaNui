// lib/shared/provider/available_languages_provider.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/shared/provider/api_client_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart'; // keyValueStorageServiceProvider

final availableLanguagesProvider = FutureProvider<List<String>>((ref) async {
  final api = ref.read(apiClientProvider);
  final storage = ref.read(keyValueStorageServiceProvider);

  const cacheKey = 'cache_available_languages_v2';

  List<String> _normalize(dynamic data) {
    List<dynamic> raw;
    if (data is Map && data['langs'] is List) {
      raw = data['langs'] as List<dynamic>;
    } else if (data is List) {
      raw = data;
    } else {
      raw = const [];
    }

    const allowed = {'es', 'en', 'pt', 'fr', 'it', 'ja'};

    final langs = raw
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .map((e) => e == 'jp' ? 'ja' : e)
        .where((e) => allowed.contains(e))
        .toSet()
        .toList();

    const order = ['es', 'en', 'pt', 'fr', 'it', 'ja'];
    langs.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

    return langs;
  }

  Future<List<String>?> _loadCache() async {
    try {
      final raw = await storage.getValue<String>(cacheKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final langs = decoded
            .map((e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .map((e) => e == 'jp' ? 'ja' : e)
            .toSet()
            .toList();

        const order = ['es', 'en', 'pt', 'fr', 'it', 'ja'];
        langs.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));

        if (langs.isNotEmpty) return langs;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveCache(List<String> langs) async {
    try {
      await storage.setKeyValue(cacheKey, jsonEncode(langs));
    } catch (_) {}
  }

  try {
    final res = await api.get(
      '/available_languages',
      queryParameters: {
        'nocache': 1,
        '_ts': DateTime.now().millisecondsSinceEpoch,
      },
      options: Options(extra: {'skip_lang': true}),
    );

    final langs = _normalize(res.data);

    if (langs.isEmpty) {
      final cached = await _loadCache();
      if (cached != null && cached.isNotEmpty) return cached;
      return const ['es', 'en', 'pt', 'fr', 'it'];
    }

    await _saveCache(langs);
    return langs;
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    // ignore: avoid_print
    print(
      'availableLanguagesProvider ERROR status=$code url=${e.requestOptions.uri}',
    );

    final cached = await _loadCache();
    if (cached != null && cached.isNotEmpty) return cached;

    return const ['es', 'en', 'pt', 'fr', 'it'];
  } catch (e) {
    // ignore: avoid_print
    print('availableLanguagesProvider ERROR: $e');

    final cached = await _loadCache();
    if (cached != null && cached.isNotEmpty) return cached;

    return const ['es', 'en', 'pt', 'fr', 'it'];
  }
});
