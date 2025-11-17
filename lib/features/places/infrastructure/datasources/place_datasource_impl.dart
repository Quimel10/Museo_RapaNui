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
    : dio = dio ?? Dio(BaseOptions(baseUrl: Environment.apiUrl));

  @override
  Future<List<PlaceEntity>> getPlaces({int? categoryId, int? page = 1}) async {
    try {
      final response = await dio.get(
        '/get_puntos',
        queryParameters: {
          if (categoryId != null) 'cat': categoryId,
          'page': page,
        },
      );
      final featured = PlaceMapper.jsonToList(response.data);
      return featured;
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

  @override
  Future<List<PlaceEntity>?> getSearch({
    int? categoryId,
    String? search,
  }) async {
    final resp = await dio.get(
      '/get_search',
      queryParameters: {
        if (categoryId != null) 'category_id': categoryId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return PlaceMapper.jsonToList(resp.data);
  }

  @override
  Future<List<CategoryEntity>> getCategory() async {
    try {
      final response = await dio.get('/get_categorias');
      final categories = CategoryMapper.jsonToList(response.data);
      return categories;
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

  @override
  Future<PlaceEntity> getPlace({String? id}) async {
    try {
      final response = await dio.get(
        '/get_punto',
        queryParameters: {if (id != null) 'post_id': id},
      );
      (response);
      final place = PlaceMapper.jsonToEntity(response.data);
      return place;
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
}
