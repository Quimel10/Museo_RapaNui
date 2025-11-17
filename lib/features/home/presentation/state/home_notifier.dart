import 'package:disfruta_antofagasta/features/home/domain/repositories/home_repository.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository repository;

  String _currentLang = 'es';

  HomeNotifier({required this.repository}) : super(HomeState.initial());

  Future<void> init(String lang) async {
    _currentLang = lang;

    // Reset de la vista
    state = state.copyWith(
      isLoadingBanners: true,
      isLoadingCategories: true,
      isLoadingPlaces: true,
      isLoadingWeather: true,
      errorMessage: null,
      errorMessageBanner: null,
      selectedCategoryId: 0,
      banners: null,
      categories: null,
      places: null,
      weather: null,
    );

    // Disparamos cargas en paralelo
    await Future.wait([
      loadBanners(),
      loadCategories(),
      loadFeaturedPlaces(),
      loadWeather(),
    ], eagerError: false);
  }

  Future<void> refresh() => init(_currentLang);
  Future<void> loadWeather() async {
    state = state.copyWith(isLoadingWeather: true, errorMessage: null);
    try {
      final weather = await repository.getWeather();
      state = state.copyWith(isLoadingWeather: false, weather: weather);
    } catch (e) {
      state = state.copyWith(
        isLoadingWeather: false,
        errorMessage: 'Error loading banners: $e',
      );
    }
  }

  Future<void> loadBanners() async {
    state = state.copyWith(isLoadingBanners: true, errorMessageBanner: null);
    try {
      final banners = await repository.getBanners();
      state = state.copyWith(
        isLoadingBanners: false,
        banners: banners,
        errorMessageBanner: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingBanners: false,
        errorMessage: 'Error loading banners: $e',
      );
    }
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoadingCategories: true, errorMessage: null);
    try {
      final categories = await repository.getFeaturedCategory();
      state = state.copyWith(
        isLoadingCategories: false,
        categories: categories,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        errorMessage: 'Error loading categories: $e',
      );
    }
  }

  Future<void> loadFeaturedPlaces() async {
    state = state.copyWith(isLoadingPlaces: true, errorMessage: null);
    try {
      final places = await repository.getFeatured(
        categoryId: state.selectedCategoryId,
      );
      state = state.copyWith(isLoadingPlaces: false, places: places);
    } catch (e) {
      state = state.copyWith(
        isLoadingPlaces: false,
        errorMessage: 'Error loading places: $e',
      );
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    if (state.selectedCategoryId == categoryId) {
      categoryId = 0; // No hacer nada si la categoría seleccionada es la misma
    }
    state = state.copyWith(selectedCategoryId: categoryId);
    await loadFeaturedPlaces();
    // Aquí podrías agregar lógica adicional, como filtrar lugares por categoría
  }
}
