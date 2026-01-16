import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/places/domain/repositories/place_repository.dart';
import 'package:disfruta_antofagasta/features/places/presentation/state/place_state.dart';
import 'package:disfruta_antofagasta/shared/utils/network_error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceNotifier extends StateNotifier<PlaceState> {
  final PlaceRepository repository;

  PlaceNotifier({required this.repository}) : super(PlaceState.initial());

  String _currentLang = 'es';

  Future<void> initForLang(String lang) async {
    _currentLang = lang;

    state = state.copyWith(
      isLoadingPlaces: true,
      isLoadingCategories: true,
      errorMessage: null,
      places: null,
      categories: null,
      page: 1,
      hasMore: true,
      isLoadingMore: false,
      search: '',
      selectedCategoryId: 0,
      // ✅ NO tocamos placeDetailsLoadedOk acá
    );

    await Future.wait([
      getPlaces(categoryId: 0, page: 1),
      loadCategories(),
    ], eagerError: false);
  }

  Future<void> refresh() => initForLang(_currentLang);

  Future<void> selectCategory(int? categoryId) async {
    final incoming = categoryId ?? 0;
    final nextCatId = (state.selectedCategoryId == incoming) ? 0 : incoming;

    state = state.copyWith(
      selectedCategoryId: nextCatId,
      page: 1,
      errorMessage: null,
    );

    final text = (state.search ?? '').trim();

    if (text.isNotEmpty) {
      await getSearch(categoryId: nextCatId, search: text);
      return;
    }

    await getPlaces(categoryId: nextCatId, page: 1);
  }

  Future<void> getPlaces({int? categoryId, int page = 1}) async {
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
        errorMessage: null,
      );
    } catch (e, st) {
      debugPrint('PlaceNotifier.getPlaces ERROR: $e');
      debugPrintStack(stackTrace: st);

      state = state.copyWith(
        isLoadingPlaces: false,
        isLoadingMore: false,
        errorMessage: NetworkError.userMessage(
          e,
          fallback: 'No pudimos cargar las piezas.\nIntenta nuevamente.',
        ),
      );
    }
  }

  Future<void> getSearch({int? categoryId, required String search}) async {
    final catId = categoryId ?? state.selectedCategoryId;
    final text = search.trim();

    if (text.isEmpty) {
      state = state.copyWith(search: '', errorMessage: null);
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
        hasMore: false,
        errorMessage: null,
      );
    } catch (e, st) {
      debugPrint('PlaceNotifier.getSearch ERROR: $e');
      debugPrintStack(stackTrace: st);

      state = state.copyWith(
        isLoadingPlaces: false,
        errorMessage: NetworkError.userMessage(
          e,
          fallback: 'No pudimos buscar en este momento.\nIntenta nuevamente.',
        ),
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
        errorMessage: null,
      );
    } catch (e, st) {
      debugPrint('PlaceNotifier.loadCategories ERROR: $e');
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

  Future<void> placeDetails(String? id) async {
    state = state.copyWith(
      placeId: id ?? 'no-id',
      isLoadingPlaceDetails: true,
      errorMessage: null,
      // ✅ IMPORTANTE: al empezar, lo marcamos como "no ok" hasta que termine bien
      placeDetailsLoadedOk: false,
    );

    try {
      final place = await repository.getPlace(id: id);

      state = state.copyWith(
        isLoadingPlaceDetails: false,
        placeDetails: place,
        errorMessage: null,
        placeDetailsLoadedOk: true, // ✅ éxito real
      );
    } catch (e, st) {
      debugPrint('PlaceNotifier.placeDetails ERROR: $e');
      debugPrintStack(stackTrace: st);

      state = state.copyWith(
        isLoadingPlaceDetails: false,
        errorMessage: NetworkError.userMessage(
          e,
          fallback: 'No pudimos cargar esta pieza.\nIntenta nuevamente.',
        ),
        placeDetailsLoadedOk: false, // ✅ falla -> debe mostrarse mensaje
      );
    }
  }
}
