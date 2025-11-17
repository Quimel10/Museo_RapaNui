import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';

abstract class PlaceRepository {
  Future<List<PlaceEntity>?> getPlaces({int? categoryId, int? page});
  Future<List<CategoryEntity>> getCategory();
  Future<List<PlaceEntity>?> getSearch({int? categoryId, String? search});
  Future<PlaceEntity> getPlace({String? id});
}
