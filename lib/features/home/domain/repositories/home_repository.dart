import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/banner.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/weather.dart';

abstract class HomeRepository {
  Future<List<BannerEntity>> getBanners();
  Future<List<CategoryEntity>> getFeaturedCategory();
  Future<List<PlaceEntity>> getFeatured({int? categoryId});
  Future<WeatherEntity> getWeather();
}
