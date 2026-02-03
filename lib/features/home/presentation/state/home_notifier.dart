import 'package:disfruta_antofagasta/features/home/domain/repositories/home_repository.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_state.dart';
import 'package:disfruta_antofagasta/shared/utils/network_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository repository;

  String _currentLang = 'es';
  int _opToken = 0;

  HomeNotifier({required this.repository}) : super(HomeState.initial());

  Future<void> init(String lang) async {
    // ✅ FIX PRO: si no haces esto, el repo sigue llamando con el idioma anterior
    _currentLang = lang;

    final token = ++_opToken;
    debugPrint('HOME init(lang=$lang) token=$token');

    if (!mounted) return;

    // ✅ Reset REAL
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

    await Future.wait([
      _loadBanners(token),
      _loadCategories(token),
      _loadFeaturedPlaces(token, categoryId: 0),
      _loadWeather(token),
    ], eagerError: false);
  }

  Future<void> refresh(String lang) async => init(lang);

  Future<void> _loadBanners(int token) async {
    if (token != _opToken || !mounted) return;

    state = state.copyWith(isLoadingBanners: true, errorMessageBanner: null);

    try {
      final banners = await repository.getBanners(_currentLang);

      if (token != _opToken || !mounted) return;

      state = state.copyWith(
        isLoadingBanners: false,
        banners: banners,
        errorMessageBanner: null,
      );
    } catch (e, st) {
      if (token != _opToken || !mounted) return;

      debugPrint('HOME _loadBanners ERROR token=$token -> $e');
      debugPrintStack(stackTrace: st);

      state = state.copyWith(
        isLoadingBanners: false,
        errorMessageBanner: NetworkError.userMessage(
          e,
          fallback: 'No pudimos cargar los banners.\nIntenta nuevamente.',
        ),
      );
    }
  }

  Future<void> _loadCategories(int token) async {
    if (token != _opToken || !mounted) return;

    state = state.copyWith(isLoadingCategories: true, errorMessage: null);

    try {
      final categories = await repository.getFeaturedCategory(_currentLang);

      if (token != _opToken || !mounted) return;

      state = state.copyWith(
        isLoadingCategories: false,
        categories: categories,
      );
    } catch (e, st) {
      if (token != _opToken || !mounted) return;

      debugPrint('HOME _loadCategories ERROR token=$token -> $e');
      debugPrintStack(stackTrace: st);

      state = state.copyWith(
        isLoadingCategories: false,
        errorMessage: NetworkError.userMessage(
          e,
          fallback: 'No pudimos cargar las categorías.\nIntenta nuevamente.',
        ),
      );
    }
  }

  Future<void> _loadFeaturedPlaces(int token, {int? categoryId}) async {
    if (token != _opToken || !mounted) return;

    state = state.copyWith(isLoadingPlaces: true, errorMessage: null);

    final catId = categoryId ?? state.selectedCategoryId ?? 0;

    try {
      final places = await repository.getFeatured(
        categoryId: catId,
        lang: _currentLang,
      );

      if (token != _opToken || !mounted) return;

      state = state.copyWith(isLoadingPlaces: false, places: places);
    } catch (e, st) {
      if (token != _opToken || !mounted) return;

      debugPrint('HOME _loadFeaturedPlaces ERROR token=$token -> $e');
      debugPrintStack(stackTrace: st);

      state = state.copyWith(
        isLoadingPlaces: false,
        errorMessage: NetworkError.userMessage(
          e,
          fallback: 'No pudimos cargar el contenido.\nIntenta nuevamente.',
        ),
      );
    }
  }

  Future<void> _loadWeather(int token) async {
    if (token != _opToken || !mounted) return;

    state = state.copyWith(isLoadingWeather: true, errorMessage: null);

    try {
      final weather = await repository.getWeather(_currentLang);

      if (token != _opToken || !mounted) return;

      state = state.copyWith(isLoadingWeather: false, weather: weather);
    } catch (e, st) {
      if (token != _opToken || !mounted) return;

      debugPrint('HOME _loadWeather ERROR token=$token -> $e');
      debugPrintStack(stackTrace: st);

      state = state.copyWith(
        isLoadingWeather: false,
        errorMessage: NetworkError.userMessage(
          e,
          fallback: 'No pudimos cargar el clima.\nIntenta nuevamente.',
        ),
      );
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    if (!mounted) return;

    final token = ++_opToken;

    var newCategoryId = categoryId;

    // Toggle: si toca la misma categoría, vuelve a 0
    if (state.selectedCategoryId == newCategoryId) {
      newCategoryId = 0;
    }

    state = state.copyWith(selectedCategoryId: newCategoryId);
    await _loadFeaturedPlaces(token, categoryId: newCategoryId ?? 0);
  }
}
