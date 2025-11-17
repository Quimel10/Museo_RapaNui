import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

class GuestFormState {
  final String name;

  /// País seleccionado completo (se persiste su `code`)
  final Country? selectedCountry;

  /// Lista de países de la API
  final List<Country> countries;

  /// Lista de regiones de la API (según país)
  final List<Region> regions;

  /// Región seleccionada (se persiste su `id`)
  final int? selectedRegionId;
  final int? age, stay;

  final bool isLoadingCountries;
  final bool isLoadingRegions;
  final bool isPosting;
  final String? error;

  const GuestFormState({
    this.name = '',
    this.selectedCountry,
    this.countries = const [],
    this.regions = const [],
    this.age,
    this.stay,

    this.selectedRegionId,
    this.isLoadingCountries = false,
    this.isLoadingRegions = false,
    this.isPosting = false,
    this.error,
  });

  /// Código del país a persistir
  String? get countryCode => selectedCountry?.code;

  /// ¿Debo mostrar selector de regiones?
  bool get needsRegion => (selectedCountry?.regionsCount ?? 0) > 1;

  bool get canSubmit =>
      name.trim().isNotEmpty &&
      countryCode != null &&
      (!needsRegion || selectedRegionId != null) &&
      !isPosting;

  GuestFormState copyWith({
    String? name,
    Country? selectedCountry,
    List<Country>? countries,
    List<Region>? regions,
    int? selectedRegionId,
    int? age,
    int? stay,
    bool? isLoadingCountries,
    bool? isLoadingRegions,
    bool? isPosting,
    String? error,
  }) {
    return GuestFormState(
      age: age ?? this.age,
      stay: stay ?? this.stay,
      name: name ?? this.name,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      countries: countries ?? this.countries,
      regions: regions ?? this.regions,
      selectedRegionId: selectedRegionId ?? this.selectedRegionId,
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      isPosting: isPosting ?? this.isPosting,
      error: error,
    );
  }
}
