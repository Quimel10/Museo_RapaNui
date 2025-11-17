import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/places/domain/repositories/place_repository.dart';
import 'package:disfruta_antofagasta/features/places/presentation/state/place_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceNotifier extends StateNotifier<PlaceState> {
  final PlaceRepository repository;

  PlaceNotifier({required this.repository}) : super(PlaceState.initial());

  String _currentLang = 'es';

  Future<void> initForLang(String lang) async {
    _currentLang = lang;

    state = state.copyWith(
      isLoadingPlaces: true,
      // añade aquí otros flags de loading que uses (categorías, filtros, etc.)
      errorMessage: null,
      // limpia colecciones si corresponde:
      places: null,
      categories: null,
      // ...
    );

    // Dispara tus cargas en paralelo o secuencial como prefieras
    await Future.wait([
      getPlaces(),
      loadCategories(), // si tienes categorías
      // _loadFilters(gen),    // si manejas filtros remotos
    ], eagerError: false);
  }

  // Si quieres un pull-to-refresh que respete el idioma actual:
  Future<void> refresh() => initForLang(_currentLang);

  Future<void> getPlaces({int? categoryId, int page = 1}) async {
    final catId = categoryId ?? state.selectedCategoryId;
    state = state.copyWith(
      selectedCategoryId: catId,
      errorMessage: null,
      isLoadingPlaces: page == 1,
      isLoadingMore: true,
      places: page == 1 ? <PlaceEntity>[] : state.places,
    );

    try {
      final results =
          await repository.getPlaces(categoryId: catId, page: page) ??
          <PlaceEntity>[];

      state = state.copyWith(
        isLoadingPlaces: false,
        isLoadingMore: false,
        page: page,
        hasMore: results.isNotEmpty, // [] => no hay más
        places: page == 1 ? results : [...state.places!, ...results],
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPlaces: false,
        isLoadingMore: false,
        errorMessage: 'Error cargando lugares: $e',
      );
    }
  }

  Future<void> getSearch({int? categoryId, required String search}) async {
    if (categoryId == state.selectedCategoryId) {
      categoryId = 0;
    }
    final catId = categoryId ?? state.selectedCategoryId;
    final text = search.trim();
    if (text.isEmpty) {
      // si limpian el texto, volvemos al listado normal
      await getPlaces(categoryId: catId, page: 1);
      return;
    }
    if (!mounted) return;
    state = state.copyWith(
      selectedCategoryId: catId,
      search: text,
      errorMessage: null,
      isLoadingPlaces: true,
      isLoadingMore: true,
      page: 1,
      places: <PlaceEntity>[],
    );

    try {
      final results =
          await repository.getSearch(categoryId: catId, search: text) ??
          <PlaceEntity>[];
      state = state.copyWith(
        isLoadingPlaces: false,
        places: results,
        hasMore: false, // sin paginación en búsqueda
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPlaces: false,
        errorMessage: 'Error buscando lugares: $e',
      );
    }
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoadingCategories: true, errorMessage: null);
    try {
      final categories = await repository.getCategory();
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

  Future<void> placeDetails(String? id) async {
    state = state.copyWith(
      placeId: id ?? 'no-id',
      isLoadingPlaceDetails: true,
      errorMessage: null,
    );
    try {
      final place = await repository.getPlace(id: id);
      state = state.copyWith(isLoadingPlaceDetails: false, placeDetails: place);
    } catch (e) {
      state = state.copyWith(
        isLoadingPlaceDetails: false,
        errorMessage: 'Error loading categories: $e',
      );
    }
  }
}
