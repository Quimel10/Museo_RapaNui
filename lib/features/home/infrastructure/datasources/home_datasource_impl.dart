import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/features/home/domain/datasources/home_datasource.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/banner.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/weather.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/banner_mapper.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/category_mapper.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/place_mapper.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/weather_mapper.dart';

class HomeDatasourceImpl extends HomeDataSource {
  late final Dio dio;
  final String accessToken;

  HomeDatasourceImpl({required this.accessToken, required Dio? dio})
    : dio = dio ?? Dio(BaseOptions(baseUrl: Environment.apiUrl)) {
    print('🌐 DIO baseUrl: ${Environment.apiUrl}');

    // quitamos siempre el Authorization
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.remove('Authorization');
          return handler.next(options);
        },
      ),
    );

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

  @override
  Future<List<BannerEntity>> getBanners() async {
    try {
      print('🌐 GET BANNERS: ${dio.options.baseUrl}/get_banners');

      final response = await dio.get(
        '/get_banners',
        queryParameters: {'lang': 'es'},
      );

      print('📡 BANNERS statusCode: ${response.statusCode}');
      print('📡 BANNERS raw: ${response.data}');

      final banners = BannerMapper.jsonToList(response.data);

      // Debug rápido para ver qué llega
      for (final b in banners) {
        print('🎯 BANNER => id:${b.id}, titulo:${b.titulo}, img:${b.img}');
      }

      return banners;
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';

      print('❌ getBanners DioException: $serverMsg');
      throw Exception('getBanners failed: $serverMsg');
    } catch (e, st) {
      print('❌ getBanners Exception: $e\n$st');
      throw Exception('getBanners failed: $e');
    }
  }

  @override
  Future<List<CategoryEntity>> getFeaturedCategory() async {
    try {
      final response = await dio.get(
        '/get_categorias_destacadas',
        queryParameters: {'lang': 'es'},
      );

      print('📡 FEATURED CATEGORIES status: ${response.statusCode}');
      print('📡 FEATURED CATEGORIES length: ${(response.data as List).length}');

      final categories = CategoryMapper.jsonToList(response.data);
      return categories;
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

  @override
  Future<List<PlaceEntity>> getFeatured({categoryId}) async {
    try {
      final response = await dio.get(
        '/get_new_destacados',
        queryParameters: {
          'lang': 'es',
          if (categoryId != null) 'cat': categoryId,
        },
      );

      print('📡 FEATURED PLACES status: ${response.statusCode}');
      print('📡 FEATURED PLACES length: ${(response.data as List).length}');

      final featured = PlaceMapper.jsonToList(response.data);
      return featured;
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

  @override
  Future<WeatherEntity> getWeather() async {
    try {
      final response = await dio.get('/get_weather');
      print('📡 WEATHER status: ${response.statusCode}');
      print('📡 WEATHER payload: ${response.data}');

      final weather = WeatherMapper.jsonToEntity(response.data);
      return weather;
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
