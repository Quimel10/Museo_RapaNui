// lib/features/auth/presentation/state/guest/guest_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'guest_state.dart';

typedef LoadCountriesFn = Future<List<Country>> Function();
typedef LoadRegionsFn = Future<List<Region>> Function(int countryId);
typedef SubmitGuestFn =
    Future<void> Function({
      required String name,
      required String countryCode,
      int? regionId,
      int? day,
      int? age,
    });

class GuestFormNotifier extends StateNotifier<GuestFormState> {
  final LoadCountriesFn loadCountries;
  final LoadRegionsFn loadRegions;
  final SubmitGuestFn submitGuest;

  GuestFormNotifier({
    required this.loadCountries,
    required this.loadRegions,
    required this.submitGuest,
  }) : super(const GuestFormState());

  // IDs para invalidar respuestas viejas si cambias de tab rápido
  int _countriesReqId = 0;
  int _regionsReqId = 0;

  /// Llamar una sola vez al montar el formulario (p. ej., en initState del GuestForm)
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

  void nameChanged(String v) {
    if (!mounted) return;
    state = state.copyWith(name: v, error: null);
  }

  void ageChanged(String v) {
    state = state.copyWith(age: int.tryParse(v)); // null si vacío/no numérico
  }

  void daysStayChanged(String v) {
    state = state.copyWith(stay: int.tryParse(v));
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

  Future<void> submit() async {
    if (!mounted) return;
    if (!state.canSubmit) return;

    state = state.copyWith(isPosting: true, error: null);
    try {
      await submitGuest(
        name: state.name.trim(),
        countryCode: state.countryCode!, // seguro gracias a canSubmit
        regionId: state.selectedRegionId,
      );
      // En éxito, AuthNotifier hace _setLoggedUser y tu listener navega.
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(error: 'Ocurrió un error. Inténtalo nuevamente.');
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      state = state.copyWith(isPosting: false);
    }
  }
}
