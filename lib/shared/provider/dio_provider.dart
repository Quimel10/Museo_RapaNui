import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  // idioma inicial
  dio.options.queryParameters['lang'] = ref.read(languageProvider);

  // mantener sincronizado si el usuario lo cambia
  ref.listen<String>(languageProvider, (prev, next) {
    dio.options.queryParameters['lang'] = next;
  });

  return dio;
});
