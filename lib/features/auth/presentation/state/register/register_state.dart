import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

class RegisterFormState {
  // existentes
  final String name, lastName, country, email, password;
  final int? region, age, stay;
  final bool accept, isPosting;
  final String? error;

  // 👈 nuevo
  final List<Country> countries;
  final List<Region> regions;
  final Country? selectedCountry;
  final int? selectedRegionId;
  final bool isLoadingCountries;
  final bool isLoadingRegions;

  const RegisterFormState({
    this.name = '',
    this.lastName = '',
    this.country = '', // puedes dejarlo, pero ya no lo usamos para enviar
    this.region,
    this.age,
    this.email = '',
    this.stay,
    this.password = '',
    this.accept = false,
    this.isPosting = false,
    this.error,

    // 👈 nuevo
    this.countries = const [],
    this.regions = const [],
    this.selectedCountry,
    this.selectedRegionId,
    this.isLoadingCountries = false,
    this.isLoadingRegions = false,
  });

  bool get isValid =>
      name.isNotEmpty &&
      lastName.isNotEmpty &&
      email.isNotEmpty &&
      password.length >= 6 &&
      accept &&
      selectedCountry != null &&
      (!needsRegion || selectedRegionId != null);

  // 👈 nuevo: código que enviaremos en el payload
  String? get countryCode => selectedCountry?.code;

  // 👈 nuevo: mostrar selector región si el país tiene >1 región
  bool get needsRegion => (selectedCountry?.regionsCount ?? 0) > 1;

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

    // 👈 nuevo
    List<Country>? countries,
    List<Region>? regions,
    Country? selectedCountry,
    int? selectedRegionId,
    bool? isLoadingCountries,
    bool? isLoadingRegions,
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

      // 👈 nuevo
      countries: countries ?? this.countries,
      regions: regions ?? this.regions,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedRegionId: selectedRegionId ?? this.selectedRegionId,
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
    );
  }
}
