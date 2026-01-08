// lib/features/auth/presentation/state/register/register_state.dart
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

/// Valores esperados:
/// "rapanui" | "continental" | "foreign"
class RegisterFormState {
  // existentes
  final String name, lastName, country, email, password;
  final int? region, age, stay;
  final bool accept, isPosting;
  final String? error;

  // catálogos
  final List<Country> countries;
  final List<Region> regions;
  final Country? selectedCountry;
  final int? selectedRegionId;
  final bool isLoadingCountries;
  final bool isLoadingRegions;

  /// ✅ NUEVO: tipo de visitante
  final String? visitorType;

  const RegisterFormState({
    this.name = '',
    this.lastName = '',
    this.country = '',
    this.region,
    this.age,
    this.email = '',
    this.stay,
    this.password = '',
    this.accept = false,
    this.isPosting = false,
    this.error,

    this.countries = const [],
    this.regions = const [],
    this.selectedCountry,
    this.selectedRegionId,
    this.isLoadingCountries = false,
    this.isLoadingRegions = false,

    // ✅ nuevo
    this.visitorType,
  });

  // payload
  String? get countryCode => selectedCountry?.code;

  bool get needsRegion => (selectedCountry?.regionsCount ?? 0) > 1;

  bool get isValid =>
      name.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      password.length >= 6 &&
      accept &&
      selectedCountry != null &&
      visitorType != null && // ✅ requerido
      (!needsRegion || selectedRegionId != null);

  RegisterFormState copyWith({
    String? name,
    String? lastName,
    String? country,
    int? region,
    int? age,
    String? email,
    int? stay,
    String? password,
    bool? accept,
    bool? isPosting,
    String? error,

    List<Country>? countries,
    List<Region>? regions,
    Country? selectedCountry,
    int? selectedRegionId,
    bool? isLoadingCountries,
    bool? isLoadingRegions,

    // ✅ nuevo
    String? visitorType,
  }) {
    return RegisterFormState(
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      region: region ?? this.region,
      age: age ?? this.age,
      email: email ?? this.email,
      stay: stay ?? this.stay,
      password: password ?? this.password,
      accept: accept ?? this.accept,
      isPosting: isPosting ?? this.isPosting,
      error: error,

      countries: countries ?? this.countries,
      regions: regions ?? this.regions,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedRegionId: selectedRegionId ?? this.selectedRegionId,
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,

      // ✅ nuevo
      visitorType: visitorType ?? this.visitorType,
    );
  }
}
