// lib/features/home/presentation/state/home_notifier.dart
import 'package:disfruta_antofagasta/features/home/domain/repositories/home_repository.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository repository;

  String _currentLang = 'es';

  // ✅ Evita carreras: cada init/refresh genera un token.
  int _opToken = 0;

  HomeNotifier({required this.repository}) : super(HomeState.initial());

  /// --- CARGA INICIAL / CAMBIO DE IDIOMA ---
  Future<void> init(String lang) async {
    _currentLang = lang;
    final token = ++_opToken;

    debugPrint('HOME init(lang=$lang) token=$token');

    // reseteamos estado
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

    // ✅ Corre en paralelo, pero cada método verifica token antes de mutar state
    await Future.wait([
      _loadBanners(token),
      _loadCategories(token),
      _loadFeaturedPlaces(token, categoryId: 0),
      _loadWeather(token),
    ], eagerError: false);

    debugPrint(
      'HOME init DONE token=$token (stillCurrent=${token == _opToken})',
    );
  }

  /// Pull-to-refresh desde Home
  Future<void> refresh(String lang) async {
    debugPrint('HOME refresh(lang=$lang)');
    return init(lang);
  }

  // ---------------- BANNERS ----------------
  Future<void> _loadBanners(int token) async {
    if (token != _opToken) return;

    state = state.copyWith(isLoadingBanners: true, errorMessageBanner: null);

    try {
      debugPrint('HOME getBanners(lang=$_currentLang) token=$token');
      final banners = await repository.getBanners(_currentLang);

      if (token != _opToken) return;
      state = state.copyWith(
        isLoadingBanners: false,
        banners: banners,
        errorMessageBanner: null,
      );
    } catch (e) {
      if (token != _opToken) return;
      state = state.copyWith(
        isLoadingBanners: false,
        errorMessageBanner: 'Error loading banners: $e',
      );
    }
  }

  // -------------- CATEGORÍAS ---------------
  Future<void> _loadCategories(int token) async {
    if (token != _opToken) return;

    state = state.copyWith(isLoadingCategories: true, errorMessage: null);

    try {
      debugPrint('HOME getFeaturedCategory(lang=$_currentLang) token=$token');
      final categories = await repository.getFeaturedCategory(_currentLang);

      if (token != _opToken) return;
      state = state.copyWith(
        isLoadingCategories: false,
        categories: categories,
      );
    } catch (e) {
      if (token != _opToken) return;
      state = state.copyWith(
        isLoadingCategories: false,
        errorMessage: 'Error loading categories: $e',
      );
    }
  }

  // ---------- LUGARES DESTACADOS ----------
  Future<void> _loadFeaturedPlaces(int token, {int? categoryId}) async {
    if (token != _opToken) return;

    state = state.copyWith(isLoadingPlaces: true, errorMessage: null);

    final catId = categoryId ?? state.selectedCategoryId ?? 0;

    try {
      debugPrint(
        'HOME getFeatured(lang=$_currentLang cat=$catId) token=$token',
      );

      final places = await repository.getFeatured(
        categoryId: catId,
        lang: _currentLang,
      );

      if (token != _opToken) return;

      debugPrint('HOME getFeatured OK -> ${places.length} items token=$token');

      state = state.copyWith(isLoadingPlaces: false, places: places);
    } catch (e) {
      if (token != _opToken) return;

      debugPrint('HOME getFeatured ERROR token=$token -> $e');

      state = state.copyWith(
        isLoadingPlaces: false,
        errorMessage: 'Error loading places: $e',
      );
    }
  }

  // ----------------- CLIMA -----------------
  Future<void> _loadWeather(int token) async {
    if (token != _opToken) return;

    state = state.copyWith(isLoadingWeather: true, errorMessage: null);

    try {
      debugPrint('HOME getWeather(lang=$_currentLang) token=$token');
      final weather = await repository.getWeather(_currentLang);

      if (token != _opToken) return;
      state = state.copyWith(isLoadingWeather: false, weather: weather);
    } catch (e) {
      if (token != _opToken) return;
      state = state.copyWith(
        isLoadingWeather: false,
        errorMessage: 'Error loading weather: $e',
      );
    }
  }

  /// --- CAMBIAR CATEGORÍA ---
  Future<void> selectCategory(int? categoryId) async {
    // token nuevo: esto cancela operaciones anteriores
    final token = ++_opToken;

    if (state.selectedCategoryId == categoryId) {
      categoryId = 0;
    }

    state = state.copyWith(selectedCategoryId: categoryId);
    await _loadFeaturedPlaces(token, categoryId: categoryId ?? 0);
  }
}
