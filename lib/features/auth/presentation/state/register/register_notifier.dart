import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';

import 'register_state.dart';

typedef LoadCountries = Future<List<Country>> Function();
typedef LoadRegionsByCode = Future<List<Region>> Function(String code);
typedef RegisterUserCallback = Future<void> Function(RegisterUser user);

class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  final LoadCountries loadCountries;
  final LoadRegionsByCode loadRegionsByCode;
  final RegisterUserCallback registerUserCallback;

  int _countriesReqId = 0;
  int _regionsReqId = 0;

  RegisterFormNotifier({
    required this.loadCountries,
    required this.loadRegionsByCode,
    required this.registerUserCallback,
  }) : super(const RegisterFormState());

  Future<void> bootstrap() async {
    final req = ++_countriesReqId;

    state = state.copyWith(isLoadingCountries: true, clearError: true);

    try {
      final list = await loadCountries();
      if (req != _countriesReqId) return;

      state = state.copyWith(isLoadingCountries: false, countries: list);
    } catch (_) {
      if (req != _countriesReqId) return;

      state = state.copyWith(
        isLoadingCountries: false,
        error: 'No pudimos cargar países.',
      );
    }
  }

  void setField(String key, String value) {
    switch (key) {
      case 'name':
        state = state.copyWith(name: value, clearError: true);
        break;
      case 'last':
        state = state.copyWith(last: value, clearError: true);
        break;
      case 'email':
        state = state.copyWith(email: value, clearError: true);
        break;
      case 'pass':
        state = state.copyWith(pass: value, clearError: true);
        break;
      case 'age':
        state = state.copyWith(
          age: int.tryParse(value.trim()),
          clearError: true,
        );
        break;
      case 'stay':
        state = state.copyWith(
          stay: int.tryParse(value.trim()),
          clearError: true,
        );
        break;
    }
  }

  void visitorTypeChanged(String v) {
    state = state.copyWith(visitorType: v, clearError: true);
  }

  Future<void> countryChanged(Country? c) async {
    if (c == null) return;

    state = state.copyWith(
      selectedCountry: c,
      regions: const [],
      clearSelectedRegion: true,
      isLoadingRegions: true,
      clearError: true,
    );

    final req = ++_regionsReqId;

    try {
      final regs = await loadRegionsByCode(c.code);
      if (req != _regionsReqId) return;

      final currentId = state.selectedRegionId;
      final exists = currentId != null && regs.any((r) => r.id == currentId);

      state = state.copyWith(
        isLoadingRegions: false,
        regions: regs,
        selectedRegionId: exists ? currentId : null,
      );
    } catch (_) {
      if (req != _regionsReqId) return;

      state = state.copyWith(
        isLoadingRegions: false,
        regions: const [],
        clearSelectedRegion: true,
      );
    }
  }

  void regionChanged(int? id) {
    state = state.copyWith(selectedRegionId: id, clearError: true);
  }

  Future<void> submit() async {
    if (state.isPosting) return;

    if (state.visitorType == null || state.visitorType!.trim().isEmpty) {
      state = state.copyWith(error: 'Selecciona el tipo de visitante.');
      return;
    }

    if (!state.canSubmit) {
      state = state.copyWith(error: 'Completa los campos requeridos.');
      return;
    }

    state = state.copyWith(isPosting: true, clearError: true);

    try {
      final countryCode = state.selectedCountry!.code.trim().toUpperCase();
      final regionId = state.needsRegion ? state.selectedRegionId : null;

      final user = RegisterUser(
        name: state.name.trim(),
        lastname: state.last.trim(),
        email: state.email.trim(),
        password: state.pass,
        countryCode: countryCode,
        visitorType: state.visitorType!.trim(),
        regionId: regionId,
        age: state.age,
        daysStay: state.stay,
      );

      await registerUserCallback(user);

      state = state.copyWith(isPosting: false);
    } catch (_) {
      state = state.copyWith(
        isPosting: false,
        error: 'No pudimos crear la cuenta.',
      );
    }
  }
}
