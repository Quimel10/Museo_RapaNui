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
      errorMessage: null,
      places: null,
      categories: null,
      // 👇 importante: reseteo consistente
      page: 1,
      hasMore: true,
      isLoadingMore: false,
      search: '',
      selectedCategoryId: 0, // 0 = "todas"
    );

    await Future.wait([
      getPlaces(categoryId: 0, page: 1),
      loadCategories(),
    ], eagerError: false);
  }

  Future<void> refresh() => initForLang(_currentLang);

  /// ✅ Toggle de categoría (mismo comportamiento que Home)
  Future<void> selectCategory(int? categoryId) async {
    // normalizamos null a 0
    final incoming = categoryId ?? 0;

    // toggle: si tocas la misma => vuelve a 0
    final nextCatId = (state.selectedCategoryId == incoming) ? 0 : incoming;

    state = state.copyWith(
      selectedCategoryId: nextCatId,
      page: 1,
      errorMessage: null,
    );

    final text = (state.search ?? '').trim();

    // si hay búsqueda activa, refrescamos búsqueda con el nuevo filtro
    if (text.isNotEmpty) {
      await getSearch(categoryId: nextCatId, search: text);
      return;
    }

    // si no hay búsqueda, refrescamos listado normal
    await getPlaces(categoryId: nextCatId, page: 1);
  }

  Future<void> getPlaces({int? categoryId, int page = 1}) async {
    // 👇 regla: si no viene categoryId, usamos el estado
    final catId = categoryId ?? state.selectedCategoryId;

    state = state.copyWith(
      selectedCategoryId: catId,
      errorMessage: null,
      isLoadingPlaces: page == 1,
      isLoadingMore: page > 1,
      page: page,
      places: page == 1 ? <PlaceEntity>[] : state.places,
    );

    try {
      final results =
          await repository.getPlaces(categoryId: catId, page: page) ??
          <PlaceEntity>[];

      state = state.copyWith(
        isLoadingPlaces: false,
        isLoadingMore: false,
        hasMore: results.isNotEmpty,
        places: page == 1 ? results : [...(state.places ?? []), ...results],
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
    // ❌ saco tu lógica rara de "si es igual => 0" de acá.
    // Eso es toggle y se maneja en selectCategory().

    final catId = categoryId ?? state.selectedCategoryId;
    final text = search.trim();

    if (text.isEmpty) {
      // si limpian el texto, volvemos al listado normal con el filtro actual
      state = state.copyWith(search: '');
      await getPlaces(categoryId: catId, page: 1);
      return;
    }

    if (!mounted) return;

    state = state.copyWith(
      selectedCategoryId: catId,
      search: text,
      errorMessage: null,
      isLoadingPlaces: true,
      isLoadingMore: false,
      page: 1,
      hasMore: false,
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
