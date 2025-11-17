import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';

abstract class PlaceDataSource {
  Future<List<PlaceEntity>> getPlaces({int? categoryId, int? page});
  Future<PlaceEntity> getPlace({String? id});
  Future<List<PlaceEntity>?> getSearch({int? categoryId, String? search});
  Future<List<CategoryEntity>> getCategory();
}
