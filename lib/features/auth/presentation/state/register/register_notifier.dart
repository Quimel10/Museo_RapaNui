// lib/features/auth/presentation/state/register/register_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';
import 'register_state.dart';

typedef LoadCountriesFn = Future<List<Country>> Function();
typedef LoadRegionsFn = Future<List<Region>> Function(int countryId);
typedef RegisterUserFn = Future<void> Function(RegisterUser req);

class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  final LoadCountriesFn loadCountries;
  final LoadRegionsFn loadRegions;
  final RegisterUserFn registerUserCallback;

  RegisterFormNotifier({
    required this.loadCountries,
    required this.loadRegions,
    required this.registerUserCallback,
  }) : super(const RegisterFormState());

  // 🔐 IDs para invalidar respuestas viejas si cambias de tab rápido
  int _countriesReqId = 0;
  int _regionsReqId = 0;

  // ====== existentes ======
  void setField(String k, String v) {
    switch (k) {
      case 'name':
        if (!mounted) return;
        state = state.copyWith(name: v);
        break;
      case 'last':
        if (!mounted) return;
        state = state.copyWith(lastName: v);
        break;
      case 'age':
        if (!mounted) return;
        state = state.copyWith(age: _toIntOrNull(v));
        break;
      case 'email':
        if (!mounted) return;
        state = state.copyWith(email: v);
        break;
      case 'stay':
        if (!mounted) return;
        state = state.copyWith(stay: _toIntOrNull(v));
        break;
      case 'pass':
        if (!mounted) return;
        state = state.copyWith(password: v);
        break;
      // ya no usamos 'country' string para enviar, pero no rompe nada
      case 'country':
        if (!mounted) return;
        state = state.copyWith(country: v);
        break;
    }
  }

  int? _toIntOrNull(String v) {
    if (v.trim().isEmpty) return null;
    return int.tryParse(v.trim());
  }

  void acceptTOS(bool v) {
    if (!mounted) return;
    state = state.copyWith(accept: v);
  }

  // ====== 👇 carga de catálogos (con guards) ======
  Future<void> bootstrap() async {
    final rid = ++_countriesReqId;

    if (!mounted) return;
    state = state.copyWith(isLoadingCountries: true, error: null);

    try {
      final items = await loadCountries();

      if (!mounted || rid != _countriesReqId) return;
      state = state.copyWith(countries: items);
    } catch (_) {
      if (!mounted || rid != _countriesReqId) return;
      state = state.copyWith(error: 'No se pudieron cargar los países');
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted || rid != _countriesReqId) return;
      state = state.copyWith(isLoadingCountries: false);
    }
  }

  Future<void> countryChanged(Country? c) async {
    if (!mounted) return;

    state = state.copyWith(
      selectedCountry: c,
      regions: const [],
      selectedRegionId: null,
      error: null,
    );
    if (c == null) return;

    if (c.regionsCount > 1) {
      final rid = ++_regionsReqId;

      state = state.copyWith(isLoadingRegions: true);
      try {
        final items = await loadRegions(c.id);

        if (!mounted || rid != _regionsReqId) return;
        state = state.copyWith(regions: items);
      } catch (_) {
        if (!mounted || rid != _regionsReqId) return;
        state = state.copyWith(error: 'No se pudieron cargar las regiones');
      } finally {
        // ignore: control_flow_in_finally
        if (!mounted || rid != _regionsReqId) return;
        state = state.copyWith(isLoadingRegions: false);
      }
    }
  }

  void regionChanged(int? id) {
    if (!mounted) return;
    state = state.copyWith(selectedRegionId: id, error: null);
  }

  // ====== submit con country_code + region_id ======
  Future<void> submit() async {
    if (!mounted) return;

    if (state.isPosting) return;
    state = state.copyWith(isPosting: true, error: null);

    try {
      final req = RegisterUser(
        name: state.name,
        lastname: state.lastName,
        email: state.email,
        password: state.password,
        countryCode: state.countryCode!, // 👈 code (CL/AR/PE)
        regionId: state.selectedRegionId, // 👈 id numérico (nullable)
        age: state.age,
        daysStay: state.stay,
        arrivalDate: null,
        departureDate: null,
      );

      await registerUserCallback(req);
      // AuthNotifier hace _setLoggedUser y navegas en tu listener
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: 'Ocurrió un error. Inténtalo nuevamente.');
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      state = state.copyWith(isPosting: false);
    }
  }
}
