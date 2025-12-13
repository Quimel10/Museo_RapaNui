import 'package:dio/dio.dart';
import 'package:disfruta_antofagasta/config/constants/enviroment.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/category_mapper.dart';
import 'package:disfruta_antofagasta/features/home/infrastructure/mappers/place_mapper.dart';
import 'package:disfruta_antofagasta/features/places/domain/datasources/place_datasource.dart';

class PlaceDatasourceImpl extends PlaceDataSource {
  late final Dio dio;
  final String accessToken;

  PlaceDatasourceImpl({required this.accessToken, required Dio? dio})
    : dio = dio ?? Dio(BaseOptions(baseUrl: Environment.apiUrl)) {
    // Igual que en Home: quitamos siempre Authorization
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.remove('Authorization');
          return handler.next(options);
        },
      ),
    );

    // Logs de debug
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

  // ---------------------------------------------------------------------------
  // LISTA DE PIEZAS (PANTALLA PIECES)
  // ---------------------------------------------------------------------------
  @override
  Future<List<PlaceEntity>> getPlaces({int? categoryId, int? page = 1}) async {
    try {
      // IMPORTANTE: aquí es donde vemos si realmente se llama al endpoint
      print(
        '📍 GET_PLACES 👉 ${dio.options.baseUrl}/get_puntos '
        '(cat: $categoryId, page: $page)',
      );

      final response = await dio.get(
        '/get_puntos',
        queryParameters: {
          if (categoryId != null && categoryId != 0) 'cat': categoryId,
          'page': page ?? 1,
          // Si el backend soporta idioma, puedes descomentar esto más tarde:
          // 'lang': 'es', // o el idioma actual si luego lo pasamos por parámetros
        },
      );

      print('📍 GET_PLACES status: ${response.statusCode}');
      print(
        '📍 GET_PLACES raw length: '
        '${(response.data is List) ? (response.data as List).length : 'no-list'}',
      );

      final places = PlaceMapper.jsonToList(response.data);

      print('📍 GET_PLACES mapped length: ${places.length}');
      for (final p in places) {
        print('   • place id:${p.id} – ${p.titulo}');
      }

      return places;
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      print('❌ getPlaces DioException: $serverMsg');
      throw Exception('getPlaces failed: $serverMsg');
    } catch (e, st) {
      print('❌ getPlaces Exception: $e\n$st');
      throw Exception('getPlaces failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // BUSCADOR
  // ---------------------------------------------------------------------------
  @override
  Future<List<PlaceEntity>?> getSearch({
    int? categoryId,
    String? search,
  }) async {
    try {
      print(
        '🔎 GET_SEARCH 👉 ${dio.options.baseUrl}/get_search '
        '(cat: $categoryId, search: "$search")',
      );

      final resp = await dio.get(
        '/get_search',
        queryParameters: {
          if (categoryId != null && categoryId != 0) 'category': categoryId,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

      print('🔎 GET_SEARCH status: ${resp.statusCode}');
      final list = PlaceMapper.jsonToList(resp.data);
      print('🔎 GET_SEARCH mapped length: ${list.length}');
      return list;
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      print('❌ getSearch DioException: $serverMsg');
      throw Exception('getSearch failed: $serverMsg');
    } catch (e, st) {
      print('❌ getSearch Exception: $e\n$st');
      throw Exception('getSearch failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // CATEGORÍAS
  // ---------------------------------------------------------------------------
  @override
  Future<List<CategoryEntity>> getCategory() async {
    try {
      print('📂 GET_CATEGORY 👉 ${dio.options.baseUrl}/get_categorias');

      final response = await dio.get('/get_categorias');

      print('📂 GET_CATEGORY status: ${response.statusCode}');
      print(
        '📂 GET_CATEGORY raw length: '
        '${(response.data is List) ? (response.data as List).length : 'no-list'}',
      );

      final categories = CategoryMapper.jsonToList(response.data);
      print('📂 GET_CATEGORY mapped length: ${categories.length}');
      return categories;
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      print('❌ getCategory DioException: $serverMsg');
      throw Exception('getCategory failed: $serverMsg');
    } catch (e, st) {
      print('❌ getCategory Exception: $e\n$st');
      throw Exception('getCategory failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DETALLE DE UNA PIEZA
  // ---------------------------------------------------------------------------
  @override
  Future<PlaceEntity> getPlace({String? id}) async {
    try {
      print('📍 GET_PLACE 👉 ${dio.options.baseUrl}/get_punto (id: $id)');

      final response = await dio.get(
        '/get_punto',
        queryParameters: {if (id != null) 'post_id': id},
      );

      print('📍 GET_PLACE status: ${response.statusCode}');
      print('📍 GET_PLACE raw: ${response.data}');

      final place = PlaceMapper.jsonToEntity(response.data);
      print('📍 GET_PLACE mapped id:${place.id} – ${place.titulo}');
      return place;
    } on DioException catch (e) {
      final serverMsg =
          (e.response?.data is Map && e.response?.data['message'] != null)
          ? e.response!.data['message'].toString()
          : e.message ?? 'Network error';
      print('❌ getPlace DioException: $serverMsg');
      throw Exception('getPlace failed: $serverMsg');
    } catch (e, st) {
      print('❌ getPlace Exception: $e\n$st');
      throw Exception('getPlace failed: $e');
    }
  }
}
