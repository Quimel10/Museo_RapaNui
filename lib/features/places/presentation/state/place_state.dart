import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';

class PlaceState {
  final int? selectedCategoryId;
  final int? page;
  final String? placeId;
  final String? search;
  final bool isLoadingCategories;
  final bool isLoadingPlaceDetails;
  final bool isLoadingMore;
  final bool hasMore;
  final bool isLoadingPlaces;
  final String? errorMessage;
  final List<PlaceEntity>? places;
  final PlaceEntity? placeDetails;
  final List<CategoryEntity>? categories;

  PlaceState({
    required this.isLoadingCategories,
    required this.isLoadingPlaceDetails,
    required this.isLoadingPlaces,
    required this.isLoadingMore,
    required this.hasMore,
    required this.page,
    this.selectedCategoryId,
    this.placeId,
    this.placeDetails,
    this.search,
    this.errorMessage,
    this.categories,
    required this.places,
  });

  factory PlaceState.initial() => PlaceState(
    isLoadingPlaces: false,
    isLoadingMore: false,
    isLoadingPlaceDetails: false,
    hasMore: false,
    selectedCategoryId: null,
    page: 1,
    isLoadingCategories: false,
    search: null,
    errorMessage: null,
    places: null,
    categories: null,
    placeDetails: null,
  );

  PlaceState copyWith({
    bool? isLoadingMore,
    bool? hasMore,
    bool? isLoadingCategories,
    bool? isLoadingPlaceDetails,
    bool? isLoadingPlaces,
    int? selectedCategoryId,
    String? placeId,
    int? page,
    String? errorMessage,
    String? search,
    PlaceEntity? placeDetails,
    List<CategoryEntity>? categories,
    List<PlaceEntity>? places,
  }) {
    return PlaceState(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingPlaceDetails:
          isLoadingPlaceDetails ?? this.isLoadingPlaceDetails,
      hasMore: hasMore ?? this.hasMore,
      placeId: placeId ?? this.placeId,
      placeDetails: placeDetails ?? this.placeDetails,
      search: search ?? this.search,
      page: page ?? this.page,
      places: places ?? this.places,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      isLoadingPlaces: isLoadingPlaces ?? this.isLoadingPlaces,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      errorMessage: errorMessage ?? this.errorMessage,
      categories: categories ?? this.categories,
    );
  }
}
