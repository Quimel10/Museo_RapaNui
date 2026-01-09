import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

class RegisterFormState {
  final String name;
  final String last;
  final String email;
  final String pass;

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

  const RegisterFormState({
    this.name = '',
    this.last = '',
    this.email = '',
    this.pass = '',
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

  bool get needsRegion => isLoadingRegions || regions.isNotEmpty;

  bool get canSubmit {
    final hasName = name.trim().isNotEmpty;
    final hasLast = last.trim().isNotEmpty;
    final hasEmail = email.trim().isNotEmpty;
    final hasPass = pass.trim().isNotEmpty;
    final hasAge = age != null && age! > 1;
    final hasStay = stay != null && stay! > 0;
    final hasCountry = selectedCountry != null;
    final hasVisitor = visitorType != null && visitorType!.trim().isNotEmpty;

    final hasRegionOk = !needsRegion || selectedRegionId != null;

    return hasName &&
        hasLast &&
        hasEmail &&
        hasPass &&
        hasAge &&
        hasStay &&
        hasCountry &&
        hasVisitor &&
        hasRegionOk;
  }

  RegisterFormState copyWith({
    String? name,
    String? last,
    String? email,
    String? pass,
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
    bool clearSelectedRegion = false,
    bool clearVisitorType = false,
  }) {
    return RegisterFormState(
      name: name ?? this.name,
      last: last ?? this.last,
      email: email ?? this.email,
      pass: pass ?? this.pass,
      age: age ?? this.age,
      stay: stay ?? this.stay,
      isPosting: isPosting ?? this.isPosting,
      error: clearError ? null : (error ?? this.error),
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      countries: countries ?? this.countries,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      regions: regions ?? this.regions,
      selectedRegionId: clearSelectedRegion
          ? null
          : (selectedRegionId ?? this.selectedRegionId),
      visitorType: clearVisitorType ? null : (visitorType ?? this.visitorType),
    );
  }
}
