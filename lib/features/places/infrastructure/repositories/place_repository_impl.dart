import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/places/domain/datasources/place_datasource.dart';
import 'package:disfruta_antofagasta/features/places/domain/repositories/place_repository.dart';

class PlaceRepositoryImpl extends PlaceRepository {
  final PlaceDataSource dataSource;
  PlaceRepositoryImpl(this.dataSource);

  @override
  Future<List<PlaceEntity>?> getPlaces({int? categoryId, int? page}) {
    return dataSource.getPlaces(categoryId: categoryId, page: page);
  }

  @override
  Future<List<PlaceEntity>?> getSearch({int? categoryId, String? search}) {
    return dataSource.getSearch(categoryId: categoryId, search: search);
  }

  @override
  Future<List<CategoryEntity>> getCategory() {
    return dataSource.getCategory();
  }

  @override
  Future<PlaceEntity> getPlace({String? id}) {
    return dataSource.getPlace(id: id);
  }
}
