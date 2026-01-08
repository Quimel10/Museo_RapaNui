import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

class GuestFormState {
  final String name;
  final String? visitorType;

  final Country? selectedCountry;
  final List<Country> countries;
  final List<Region> regions;
  final int? selectedRegionId;
  final int? age, stay;

  final bool isLoadingCountries;
  final bool isLoadingRegions;
  final bool isPosting;
  final String? error;

  const GuestFormState({
    this.name = '',
    this.visitorType,
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

  String? get countryCode => selectedCountry?.code;
  bool get needsRegion => (selectedCountry?.regionsCount ?? 0) > 1;

  bool get canSubmit =>
      name.trim().isNotEmpty &&
      visitorType != null &&
      countryCode != null &&
      (!needsRegion || selectedRegionId != null) &&
      !isPosting;

  GuestFormState copyWith({
    String? name,
    String? visitorType,
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
      name: name ?? this.name,
      visitorType: visitorType ?? this.visitorType,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      countries: countries ?? this.countries,
      regions: regions ?? this.regions,
      selectedRegionId: selectedRegionId ?? this.selectedRegionId,
      age: age ?? this.age,
      stay: stay ?? this.stay,
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      isPosting: isPosting ?? this.isPosting,
      error: error,
    );
  }
}
