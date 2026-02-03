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

  const HomeState({
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

  factory HomeState.initial() => const HomeState(
    isLoadingWeather: false,
    isLoadingBanners: false,
    isLoadingPlaces: false,
    selectedCategoryId: null,
    isLoadingCategories: false,
    errorMessage: null,
    errorMessageBanner: null,
    banners: null,
    weather: null,
    categories: null,
    places: null,
  );

  static const _unset = Object();

  HomeState copyWith({
    bool? isLoadingBanners,
    bool? isLoadingWeather,
    bool? isLoadingCategories,
    bool? isLoadingPlaces,
    int? selectedCategoryId,

    Object? errorMessage = _unset,
    Object? errorMessageBanner = _unset,

    Object? banners = _unset,
    Object? categories = _unset,
    Object? places = _unset,
    Object? weather = _unset,
  }) {
    return HomeState(
      isLoadingBanners: isLoadingBanners ?? this.isLoadingBanners,
      isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingPlaces: isLoadingPlaces ?? this.isLoadingPlaces,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,

      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      errorMessageBanner: identical(errorMessageBanner, _unset)
          ? this.errorMessageBanner
          : errorMessageBanner as String?,

      banners: identical(banners, _unset)
          ? this.banners
          : banners as List<BannerEntity>?,
      categories: identical(categories, _unset)
          ? this.categories
          : categories as List<CategoryEntity>?,
      places: identical(places, _unset)
          ? this.places
          : places as List<PlaceEntity>?,
      weather: identical(weather, _unset)
          ? this.weather
          : weather as WeatherEntity?,
    );
  }
}
