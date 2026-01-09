import 'package:disfruta_antofagasta/features/home/domain/datasources/home_datasource.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/banner.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/weather.dart';
import 'package:disfruta_antofagasta/features/home/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource dataSource;

  /// ✅ Lo dejamos por compatibilidad con tu provider/constructor,
  /// pero NO cacheamos aquí (el datasource ya cachea el JSON real).
  final dynamic storage;

  HomeRepositoryImpl({required this.dataSource, required this.storage});

  String _normLang(String lang) {
    final v = lang.trim().toLowerCase();
    const allowed = {'es', 'en', 'pt', 'fr', 'it', 'ja'};
    return allowed.contains(v) ? v : 'es';
  }

  @override
  Future<List<BannerEntity>> getBanners(String lang) {
    return dataSource.getBanners(_normLang(lang));
  }

  @override
  Future<List<CategoryEntity>> getFeaturedCategory(String lang) {
    return dataSource.getFeaturedCategory(_normLang(lang));
  }

  @override
  Future<List<PlaceEntity>> getFeatured({
    int? categoryId,
    required String lang,
  }) {
    return dataSource.getFeatured(
      categoryId: categoryId,
      lang: _normLang(lang),
    );
  }

  @override
  Future<WeatherEntity> getWeather(String lang) {
    return dataSource.getWeather(_normLang(lang));
  }
}
