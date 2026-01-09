import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/features/home/domain/datasources/home_datasource.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/banner.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/weather.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/banner_mapper.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/category_mapper.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/place_mapper.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/weather_mapper.dart';

class HomeDatasourceImpl extends HomeDataSource {
  final Dio dio;
  final String accessToken;

  /// ✅ storage opcional para cachear response.data (JSON real)
  /// Debe tener: getValue<T>(key), setKeyValue(key, value)
  final dynamic storage;

  static const int _ttlHours = 24;

  HomeDatasourceImpl({required this.accessToken, this.storage, Dio? dio})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Environment.apiUrl,
              connectTimeout: const Duration(seconds: 12),
              sendTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 18),
              responseType: ResponseType.json,
              headers: {'Accept': 'application/json'},
            ),
          ) {
    // sacamos siempre Authorization
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.remove('Authorization');

          // ✅ reforzar no-cache client-side
          options.headers['Cache-Control'] = 'no-cache';
          options.headers['Pragma'] = 'no-cache';

          return handler.next(options);
        },
      ),
    );

    // logs
    this.dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  String _normLang(String lang) {
    final v = lang.trim().toLowerCase();
    const allowed = {'es', 'en', 'pt', 'fr', 'it', 'ja'};
    return allowed.contains(v) ? v : 'es';
  }

  void _ensureListResponse(dynamic data, String endpoint) {
    if (data is List) return;
    throw Exception('$endpoint failed: response is not a List');
  }

  // ------- Cache helpers -------
  String _k(String lang, String key) => 'home_cache:$lang:$key';
  String _kTs(String lang, String key) => 'home_cache:$lang:$key:ts';

  bool _isFresh(int? tsMillis) {
    if (tsMillis == null) return false;
    final ts = DateTime.fromMillisecondsSinceEpoch(tsMillis);
    return DateTime.now().difference(ts).inHours < _ttlHours;
  }

  Future<void> _cacheSet(String lang, String key, Object jsonObj) async {
    if (storage == null) return;
    await storage.setKeyValue(_k(lang, key), jsonEncode(jsonObj));
    await storage.setKeyValue(
      _kTs(lang, key),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<dynamic> _cacheGet(String lang, String key) async {
    if (storage == null) return null;
    final raw = await storage.getValue<String>(_k(lang, key));
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<int?> _cacheTs(String lang, String key) async {
    if (storage == null) return null;
    return storage.getValue<int>(_kTs(lang, key));
  }

  // -------- BANNERS --------
  @override
  Future<List<BannerEntity>> getBanners(String lang) async {
    final l = _normLang(lang);
    const cacheKey = 'banners';

    final ts = await _cacheTs(l, cacheKey);
    if (_isFresh(ts)) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is List) return BannerMapper.jsonToList(cached);
    }

    try {
      final response = await dio.get(
        '/get_banners',
        queryParameters: {
          'lang': l,
          '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );

      _ensureListResponse(response.data, 'get_banners');
      await _cacheSet(l, cacheKey, response.data);

      return BannerMapper.jsonToList(response.data);
    } on DioException catch (e) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is List && cached.isNotEmpty) {
        return BannerMapper.jsonToList(cached);
      }

      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      throw Exception('getBanners failed: $serverMsg');
    } catch (e) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is List && cached.isNotEmpty) {
        return BannerMapper.jsonToList(cached);
      }
      throw Exception('getBanners failed: $e');
    }
  }

  // ---- CATEGORÍAS DESTACADAS ----
  @override
  Future<List<CategoryEntity>> getFeaturedCategory(String lang) async {
    final l = _normLang(lang);
    const cacheKey = 'featured_categories';

    final ts = await _cacheTs(l, cacheKey);
    if (_isFresh(ts)) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is List) return CategoryMapper.jsonToList(cached);
    }

    try {
      final response = await dio.get(
        '/get_categorias_destacadas',
        queryParameters: {
          'lang': l,
          '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );

      _ensureListResponse(response.data, 'get_categorias_destacadas');
      await _cacheSet(l, cacheKey, response.data);

      return CategoryMapper.jsonToList(response.data);
    } on DioException catch (e) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is List && cached.isNotEmpty) {
        return CategoryMapper.jsonToList(cached);
      }

      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      throw Exception('getFeaturedCategory failed: $serverMsg');
    } catch (e) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is List && cached.isNotEmpty) {
        return CategoryMapper.jsonToList(cached);
      }
      throw Exception('getFeaturedCategory failed: $e');
    }
  }

  // -------- DESTACADOS HOME --------
  @override
  Future<List<PlaceEntity>> getFeatured({
    int? categoryId,
    required String lang,
  }) async {
    final l = _normLang(lang);
    final cid = categoryId ?? 0;
    final cacheKey = 'featured_cat_$cid';

    // ✅ CLAVE: NO cache-first para destacados.
    // Siempre intentamos RED para que aparezca inmediatamente lo nuevo.
    // Cache solo como fallback si falla la red.
    try {
      final response = await dio.get(
        '/get_new_destacados',
        queryParameters: {
          'lang': l,
          'cat': cid, // ✅ siempre manda cat (0 incluido)
          '_ts': DateTime.now().millisecondsSinceEpoch, // ✅ cache buster
        },
      );

      _ensureListResponse(response.data, 'get_new_destacados');
      await _cacheSet(l, cacheKey, response.data);

      return PlaceMapper.jsonToList(response.data);
    } on DioException catch (e) {
      // fallback cache aunque esté viejo
      final cached = await _cacheGet(l, cacheKey);
      if (cached is List && cached.isNotEmpty) {
        return PlaceMapper.jsonToList(cached);
      }

      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      throw Exception('getFeatured failed: $serverMsg');
    } catch (e) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is List && cached.isNotEmpty) {
        return PlaceMapper.jsonToList(cached);
      }
      throw Exception('getFeatured failed: $e');
    }
  }

  // ------------- CLIMA -------------
  @override
  Future<WeatherEntity> getWeather(String lang) async {
    final l = _normLang(lang);
    const cacheKey = 'weather';

    final ts = await _cacheTs(l, cacheKey);
    if (_isFresh(ts)) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is Map) {
        return WeatherMapper.jsonToEntity(Map<String, dynamic>.from(cached));
      }
    }

    try {
      final response = await dio.get(
        '/get_weather',
        queryParameters: {
          'lang': l,
          '_ts': DateTime.now().millisecondsSinceEpoch,
        },
      );

      await _cacheSet(l, cacheKey, response.data);

      return WeatherMapper.jsonToEntity(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is Map && cached.isNotEmpty) {
        return WeatherMapper.jsonToEntity(Map<String, dynamic>.from(cached));
      }

      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      throw Exception('getWeather failed: $serverMsg');
    } catch (e) {
      final cached = await _cacheGet(l, cacheKey);
      if (cached is Map && cached.isNotEmpty) {
        return WeatherMapper.jsonToEntity(Map<String, dynamic>.from(cached));
      }
      throw Exception('getWeather failed: $e');
    }
  }
}
