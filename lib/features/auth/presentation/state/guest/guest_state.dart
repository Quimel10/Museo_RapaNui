import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

class GuestFormState {
  final String name;
  final int? age;
  final int? stay;

  final bool isPosting;
  final String? error;

  final bool isLoadingCountries;
  final List<Country> countries;
  final Country? selectedCountry;

  final bool isLoadingRegions;
  final List<Region> regions;
  final int? selectedRegionId;

  /// ✅ ahora NO preseleccionamos
  final String? visitorType;

  const GuestFormState({
    this.name = '',
    this.age,
    this.stay,
    this.isPosting = false,
    this.error,
    this.isLoadingCountries = false,
    this.countries = const [],
    this.selectedCountry,
    this.isLoadingRegions = false,
    this.regions = const [],
    this.selectedRegionId,
    this.visitorType,
  });

  /// ✅ Mostrar región solo si:
  /// - estamos cargando regiones, o
  /// - ya llegaron regiones (no vacío)
  bool get needsRegion => isLoadingRegions || regions.isNotEmpty;

  bool get canSubmit {
    final hasName = name.trim().isNotEmpty;
    final hasAge = age != null && age! > 1;
    final hasStay = stay != null && stay! > 0;
    final hasCountry = selectedCountry != null;
    final hasVisitor = visitorType != null && visitorType!.trim().isNotEmpty;

    // si needsRegion => region obligatoria
    final hasRegionOk = !needsRegion || selectedRegionId != null;

    return hasName &&
        hasAge &&
        hasStay &&
        hasCountry &&
        hasVisitor &&
        hasRegionOk;
  }

  GuestFormState copyWith({
    String? name,
    int? age,
    int? stay,
    bool? isPosting,
    String? error,
    bool? isLoadingCountries,
    List<Country>? countries,
    Country? selectedCountry,
    bool? isLoadingRegions,
    List<Region>? regions,
    int? selectedRegionId,
    String? visitorType,
    bool clearError = false,
    bool clearSelectedCountry = false,
    bool clearSelectedRegion = false,
    bool clearVisitorType = false,
  }) {
    return GuestFormState(
      name: name ?? this.name,
      age: age ?? this.age,
      stay: stay ?? this.stay,
      isPosting: isPosting ?? this.isPosting,
      error: clearError ? null : (error ?? this.error),
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      countries: countries ?? this.countries,
      selectedCountry: clearSelectedCountry
          ? null
          : (selectedCountry ?? this.selectedCountry),
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      regions: regions ?? this.regions,
      selectedRegionId: clearSelectedRegion
          ? null
          : (selectedRegionId ?? this.selectedRegionId),
      visitorType: clearVisitorType ? null : (visitorType ?? this.visitorType),
    );
  }
}
