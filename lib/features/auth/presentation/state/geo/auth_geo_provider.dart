import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/datasources/auth_datasource_impl.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/geo/auth_geo_datasource_provider.dart';

class AuthGeoState {
  final bool isLoadingCountries;
  final bool isLoadingRegions;
  final List<Country> countries;
  final List<Region> regions;
  final String? lastCountryCode;
  final String? error;

  const AuthGeoState({
    this.isLoadingCountries = false,
    this.isLoadingRegions = false,
    this.countries = const [],
    this.regions = const [],
    this.lastCountryCode,
    this.error,
  });

  AuthGeoState copyWith({
    bool? isLoadingCountries,
    bool? isLoadingRegions,
    List<Country>? countries,
    List<Region>? regions,
    String? lastCountryCode,
    String? error,
  }) {
    return AuthGeoState(
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      countries: countries ?? this.countries,
      regions: regions ?? this.regions,
      lastCountryCode: lastCountryCode ?? this.lastCountryCode,
      error: error,
    );
  }
}

class AuthGeoNotifier extends StateNotifier<AuthGeoState> {
  final AuthDataSourceImpl ds;

  CancelToken? _countriesToken;
  CancelToken? _regionsToken;

  AuthGeoNotifier(this.ds) : super(const AuthGeoState());

  Future<void> loadCountries() async {
    // cancela si había una request anterior
    _countriesToken?.cancel('new countries request');
    _countriesToken = CancelToken();

    state = state.copyWith(isLoadingCountries: true, error: null);

    try {
      final list = await ds.countries(cancelToken: _countriesToken);

      state = state.copyWith(isLoadingCountries: false, countries: list);
    } catch (e) {
      // si fue cancelado, no lo marques como error
      if (_countriesToken?.isCancelled == true) {
        state = state.copyWith(isLoadingCountries: false);
        return;
      }
      state = state.copyWith(
        isLoadingCountries: false,
        countries: const [],
        error: e.toString(),
      );
    }
  }

  Future<void> loadRegionsByCountryCode(String countryCode) async {
    final cc = countryCode.trim().toUpperCase();
    if (cc.isEmpty) return;

    // cancela si había una request anterior
    _regionsToken?.cancel('new regions request');
    _regionsToken = CancelToken();

    state = state.copyWith(
      isLoadingRegions: true,
      regions: const [],
      lastCountryCode: cc,
      error: null,
    );

    try {
      final list = await ds.regionsByCountryCode(
        cc,
        cancelToken: _regionsToken,
      );

      state = state.copyWith(isLoadingRegions: false, regions: list);
    } catch (e) {
      if (_regionsToken?.isCancelled == true) {
        state = state.copyWith(isLoadingRegions: false);
        return;
      }
      state = state.copyWith(
        isLoadingRegions: false,
        regions: const [],
        error: e.toString(),
      );
    }
  }

  void clearRegions() {
    state = state.copyWith(
      regions: const [],
      lastCountryCode: null,
      error: null,
    );
  }

  @override
  void dispose() {
    _countriesToken?.cancel('dispose');
    _regionsToken?.cancel('dispose');
    super.dispose();
  }
}

final authGeoProvider =
    StateNotifierProvider.autoDispose<AuthGeoNotifier, AuthGeoState>((ref) {
      final ds = ref.read(authGeoDataSourceProvider);
      return AuthGeoNotifier(ds);
    });
