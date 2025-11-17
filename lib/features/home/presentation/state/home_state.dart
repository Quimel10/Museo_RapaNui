import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/banner.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/weather.dart';

class HomeState {
  final bool isLoadingBanners;
  final int? selectedCategoryId;
  final bool isLoadingCategories;
  final bool isLoadingPlaces;
  final bool isLoadingWeather;
  final String? errorMessage;
  final String? errorMessageBanner;
  final WeatherEntity? weather;
  final List<BannerEntity>? banners;
  final List<PlaceEntity>? places;
  final List<CategoryEntity>? categories;
  HomeState({
    required this.isLoadingBanners,
    required this.isLoadingCategories,
    required this.isLoadingPlaces,
    required this.isLoadingWeather,
    this.banners,
    this.selectedCategoryId,
    this.weather,
    this.errorMessage,
    this.errorMessageBanner,
    this.categories,
    this.places,
  });

  factory HomeState.initial() => HomeState(
    isLoadingWeather: false,
    isLoadingBanners: false,
    isLoadingPlaces: false,
    selectedCategoryId: null,
    isLoadingCategories: false,
    errorMessage: null,
    errorMessageBanner: null,
    banners: null,
    weather: null,
    places: null,
  );

  HomeState copyWith({
    bool? isLoadingBanners,
    bool? isLoadingWeather,
    bool? isLoadingCategories,
    bool? isLoadingPlaces,
    int? selectedCategoryId,
    String? errorMessage,
    String? errorMessageBanner,
    List<BannerEntity>? banners,
    List<CategoryEntity>? categories,
    List<PlaceEntity>? places,
    WeatherEntity? weather,
  }) {
    return HomeState(
      places: places ?? this.places,
      errorMessageBanner: errorMessageBanner ?? this.errorMessageBanner,
      weather: weather ?? this.weather,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
      isLoadingPlaces: isLoadingPlaces ?? this.isLoadingPlaces,
      isLoadingBanners: isLoadingBanners ?? this.isLoadingBanners,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      errorMessage: errorMessage ?? this.errorMessage,
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
    );
  }
}
