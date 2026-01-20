import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/register_user.dart';

import 'register_state.dart';

typedef LoadCountries = Future<List<Country>> Function();
typedef LoadRegionsByCode = Future<List<Region>> Function(String countryCode);
typedef RegisterUserCallback = Future<void> Function(RegisterUser user);

class RegisterFormNotifier extends StateNotifier<RegisterFormState> {
  final LoadCountries loadCountries;
  final LoadRegionsByCode loadRegionsByCode;
  final RegisterUserCallback registerUserCallback;

  CancelableOperation<List<Region>>? _regionsOp;

  RegisterFormNotifier({
    required this.loadCountries,
    required this.loadRegionsByCode,
    required this.registerUserCallback,
  }) : super(const RegisterFormState());

  Future<void> bootstrap() async {
    state = state.copyWith(isLoadingCountries: true, clearError: true);

    try {
      final list = await loadCountries();
      state = state.copyWith(isLoadingCountries: false, countries: list);
    } catch (e) {
      state = state.copyWith(
        isLoadingCountries: false,
        error: 'No se pudieron cargar países',
      );
    }
  }

  void setField(String key, String value) {
    switch (key) {
      case 'name':
        state = state.copyWith(name: value, clearError: true);
        return;
      case 'last':
        state = state.copyWith(last: value, clearError: true);
        return;
      case 'email':
        state = state.copyWith(email: value, clearError: true);
        return;
      case 'pass':
        state = state.copyWith(pass: value, clearError: true);
        return;
      case 'age':
        final v = int.tryParse(value.trim());
        state = state.copyWith(age: v, clearError: true);
        return;
      case 'stay':
        final v = int.tryParse(value.trim());
        state = state.copyWith(stay: v, clearError: true);
        return;
      default:
        return;
    }
  }

  Future<void> countryChanged(Country? c) async {
    state = state.copyWith(
      selectedCountry: c,
      clearError: true,
      clearSelectedRegion: true,
    );

    if (c == null) {
      state = state.copyWith(isLoadingRegions: false, regions: const []);
      return;
    }

    // Cancelar request anterior de regiones si existe
    await _regionsOp?.cancel();

    // Si tu backend decide “needsRegion” por tener regiones,
    // cargamos y si viene vacío -> el dropdown no se renderiza.
    state = state.copyWith(isLoadingRegions: true, regions: const []);

    final op = CancelableOperation.fromFuture(loadRegionsByCode(c.code));
    _regionsOp = op;

    try {
      final list = await op.value;
      // si otro op se creó después, ignoramos este resultado
      if (_regionsOp != op) return;

      state = state.copyWith(isLoadingRegions: false, regions: list);
    } catch (_) {
      if (_regionsOp != op) return;
      state = state.copyWith(isLoadingRegions: false, regions: const []);
    }
  }

  void regionChanged(int? id) {
    state = state.copyWith(selectedRegionId: id, clearError: true);
  }

  /// ✅ Aquí se setea el KEY canónico desde el dropdown:
  /// local_rapanui | local_no_rapanui | continental | extranjero
  void visitorTypeChanged(String v) {
    state = state.copyWith(visitorType: v, clearError: true);
  }

  Future<void> submit() async {
    if (state.isPosting) return;

    if (!state.canSubmit) {
      state = state.copyWith(error: 'Completa todos los campos requeridos.');
      return;
    }

    state = state.copyWith(isPosting: true, clearError: true);

    try {
      final user = RegisterUser(
        name: state.name,
        lastname: state.last,
        email: state.email,
        password: state.pass,
        countryCode: state.selectedCountry!.code,
        regionId: state.needsRegion ? state.selectedRegionId : null,
        age: state.age,
        daysStay: state.stay,
        visitorType: state.visitorType!, // ✅ KEY canónico
        device: null,
        arrivalDate: null,
        departureDate: null,
      );

      await registerUserCallback(user);

      state = state.copyWith(isPosting: false);
    } catch (e) {
      state = state.copyWith(
        isPosting: false,
        error: 'No se pudo crear la cuenta. Intenta nuevamente.',
      );
    }
  }

  @override
  void dispose() {
    _regionsOp?.cancel();
    super.dispose();
  }
}

/// Pequeña utilidad de cancelación sin traer paquetes externos.
class CancelableOperation<T> {
  final Future<T> _future;
  bool _isCanceled = false;

  CancelableOperation._(this._future);

  Future<T> get value async {
    final v = await _future;
    if (_isCanceled) {
      throw StateError('Canceled');
    }
    return v;
  }

  Future<void> cancel() async {
    _isCanceled = true;
  }

  static CancelableOperation<T> fromFuture<T>(Future<T> f) {
    return CancelableOperation._(f);
  }
}
