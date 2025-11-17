import 'package:disfruta_antofagasta/features/home/domain/datasources/home_datasource.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/banner.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/weather.dart';
import 'package:disfruta_antofagasta/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl extends HomeRepository {
  final HomeDataSource dataSource;
  HomeRepositoryImpl(this.dataSource);

  @override
  Future<List<BannerEntity>> getBanners() {
    return dataSource.getBanners();
  }

  @override
  Future<List<CategoryEntity>> getFeaturedCategory() {
    return dataSource.getFeaturedCategory();
  }

  @override
  Future<List<PlaceEntity>> getFeatured({int? categoryId}) {
    return dataSource.getFeatured(categoryId: categoryId);
  }

  @override
  Future<WeatherEntity> getWeather() {
    return dataSource.getWeather();
  }
}
