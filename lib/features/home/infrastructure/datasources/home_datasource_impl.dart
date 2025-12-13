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

  HomeDatasourceImpl({required this.accessToken, Dio? dio})
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
    // dejamos pasar it/ja aunque WP no los tenga: WP debe responder [] si no existen
    const allowed = {'es', 'en', 'pt', 'fr', 'it', 'ja'};
    return allowed.contains(v) ? v : 'es';
  }

  void _ensureListResponse(dynamic data, String endpoint) {
    if (data is List) return;
    throw Exception('$endpoint failed: response is not a List');
  }

  // -------- BANNERS --------
  @override
  Future<List<BannerEntity>> getBanners(String lang) async {
    final l = _normLang(lang);
    try {
      final response = await dio.get(
        '/get_banners',
        queryParameters: {'lang': l},
      );

      _ensureListResponse(response.data, 'get_banners');
      return BannerMapper.jsonToList(response.data);
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      throw Exception('getBanners failed: $serverMsg');
    } catch (e) {
      throw Exception('getBanners failed: $e');
    }
  }

  // ---- CATEGORÍAS DESTACADAS ----
  @override
  Future<List<CategoryEntity>> getFeaturedCategory(String lang) async {
    final l = _normLang(lang);
    try {
      final response = await dio.get(
        '/get_categorias_destacadas',
        queryParameters: {'lang': l},
      );

      _ensureListResponse(response.data, 'get_categorias_destacadas');
      return CategoryMapper.jsonToList(response.data);
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      throw Exception('getFeaturedCategory failed: $serverMsg');
    } catch (e) {
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
    try {
      final response = await dio.get(
        '/get_new_destacados',
        queryParameters: {'lang': l, if (categoryId != null) 'cat': categoryId},
      );

      _ensureListResponse(response.data, 'get_new_destacados');
      return PlaceMapper.jsonToList(response.data);
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      throw Exception('getFeatured failed: $serverMsg');
    } catch (e) {
      throw Exception('getFeatured failed: $e');
    }
  }

  // ------------- CLIMA -------------
  @override
  Future<WeatherEntity> getWeather(String lang) async {
    final l = _normLang(lang);
    try {
      final response = await dio.get(
        '/get_weather',
        queryParameters: {'lang': l},
      );

      return WeatherMapper.jsonToEntity(response.data);
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      throw Exception('getWeather failed: $serverMsg');
    } catch (e) {
      throw Exception('getWeather failed: $e');
    }
  }
}
