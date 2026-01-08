import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';
import 'register_state.dart';

typedef LoadCountriesFn = Future<List<Country>> Function();
typedef LoadRegionsByCodeFn = Future<List<Region>> Function(String countryCode);
typedef RegisterUserFn = Future<void> Function(RegisterUser req);

class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  final LoadCountriesFn loadCountries;
  final LoadRegionsByCodeFn loadRegionsByCode;
  final RegisterUserFn registerUserCallback;

  RegisterFormNotifier({
    required this.loadCountries,
    required this.loadRegionsByCode,
    required this.registerUserCallback,
  }) : super(const RegisterFormState());

  int _countriesReqId = 0;
  int _regionsReqId = 0;

  void setField(String k, String v) {
    if (!mounted) return;

    switch (k) {
      case 'name':
        state = state.copyWith(name: v, error: null);
        break;
      case 'last':
        state = state.copyWith(lastName: v, error: null);
        break;
      case 'age':
        state = state.copyWith(age: _toIntOrNull(v), error: null);
        break;
      case 'email':
        state = state.copyWith(email: v, error: null);
        break;
      case 'stay':
        state = state.copyWith(stay: _toIntOrNull(v), error: null);
        break;
      case 'pass':
        state = state.copyWith(password: v, error: null);
        break;
      case 'country':
        state = state.copyWith(country: v, error: null);
        break;
    }
  }

  int? _toIntOrNull(String v) {
    final t = v.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  void acceptTOS(bool v) {
    if (!mounted) return;
    state = state.copyWith(accept: v, error: null);
  }

  void visitorTypeChanged(String? v) {
    if (!mounted) return;
    state = state.copyWith(visitorType: v, error: null);
  }

  Future<void> bootstrap() async {
    final rid = ++_countriesReqId;
    state = state.copyWith(isLoadingCountries: true, error: null);

    try {
      final items = await loadCountries();
      if (!mounted || rid != _countriesReqId) return;
      state = state.copyWith(countries: items);
    } catch (_) {
      if (!mounted || rid != _countriesReqId) return;
      state = state.copyWith(error: 'No se pudieron cargar los países');
    } finally {
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

    // ✅ FIX: SIEMPRE intentar cargar regiones.
    final rid = ++_regionsReqId;
    state = state.copyWith(isLoadingRegions: true);

    try {
      final items = await loadRegionsByCode(c.code);
      if (!mounted || rid != _regionsReqId) return;

      final active = items.where((r) => r.active).toList();
      state = state.copyWith(regions: active);
    } catch (_) {
      if (!mounted || rid != _regionsReqId) return;
      state = state.copyWith(error: 'No se pudieron cargar las regiones');
    } finally {
      if (!mounted || rid != _regionsReqId) return;
      state = state.copyWith(isLoadingRegions: false);
    }
  }

  void regionChanged(int? id) {
    if (!mounted) return;
    state = state.copyWith(selectedRegionId: id, error: null);
  }

  Future<void> submit() async {
    if (!mounted) return;

    if (!state.isValid || state.visitorType == null) {
      state = state.copyWith(error: 'Completa todos los campos requeridos.');
      return;
    }

    if (state.isPosting) return;
    state = state.copyWith(isPosting: true, error: null);

    try {
      final req = RegisterUser(
        name: state.name.trim(),
        lastname: state.lastName.trim(),
        email: state.email.trim(),
        password: state.password,
        countryCode: state.countryCode!,
        regionId: state.selectedRegionId,
        age: state.age,
        daysStay: state.stay,
        visitorType: state.visitorType!,
      );

      await registerUserCallback(req);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(error: 'Ocurrió un error. Inténtalo nuevamente.');
    } finally {
      if (!mounted) return;
      state = state.copyWith(isPosting: false);
    }
  }
}
