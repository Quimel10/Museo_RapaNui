import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/geo/auth_geo_datasource_provider.dart';

class AuthGeoState {
  final bool isLoadingCountries;
  final bool isLoadingRegions;
  final List<Country> countries;
  final List<Region> regions;

  const AuthGeoState({
    this.isLoadingCountries = false,
    this.isLoadingRegions = false,
    this.countries = const [],
    this.regions = const [],
  });

  AuthGeoState copyWith({
    bool? isLoadingCountries,
    bool? isLoadingRegions,
    List<Country>? countries,
    List<Region>? regions,
  }) {
    return AuthGeoState(
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      countries: countries ?? this.countries,
      regions: regions ?? this.regions,
    );
  }
}

class AuthGeoNotifier extends StateNotifier<AuthGeoState> {
  final AuthGeoDataSource ds;

  AuthGeoNotifier(this.ds) : super(const AuthGeoState());

  Future<void> loadCountries() async {
    state = state.copyWith(isLoadingCountries: true);
    final list = await ds.countries();

    // ✅ Importante: solo lo que viene de WP (ya viene filtrado por active en backend)
    state = state.copyWith(isLoadingCountries: false, countries: list);
  }

  Future<void> loadRegionsByCountryCode(String code) async {
    state = state.copyWith(isLoadingRegions: true, regions: const []);
    final list = await ds.regionsByCountryCode(code);
    state = state.copyWith(isLoadingRegions: false, regions: list);
  }

  void clearRegions() {
    state = state.copyWith(isLoadingRegions: false, regions: const []);
  }
}

final authGeoProvider = StateNotifierProvider<AuthGeoNotifier, AuthGeoState>((
  ref,
) {
  final ds = ref.read(authGeoDataSourceProvider);
  return AuthGeoNotifier(ds);
});
