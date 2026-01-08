import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';
import 'guest_state.dart';

typedef LoadCountriesFn = Future<List<Country>> Function();
typedef LoadRegionsByCodeFn = Future<List<Region>> Function(String countryCode);

typedef SubmitGuestFn =
    Future<void> Function({
      required String name,
      required String countryCode,
      required String visitorType,
      int? regionId,
      int? day,
      int? age,
    });

class GuestFormNotifier extends StateNotifier<GuestFormState> {
  final LoadCountriesFn loadCountries;
  final LoadRegionsByCodeFn loadRegionsByCode;
  final SubmitGuestFn submitGuest;

  GuestFormNotifier({
    required this.loadCountries,
    required this.loadRegionsByCode,
    required this.submitGuest,
  }) : super(const GuestFormState());

  int _countriesReqId = 0;
  int _regionsReqId = 0;

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
      if (!mounted || rid != _countriesReqId) return;
      state = state.copyWith(isLoadingCountries: false);
    }
  }

  void nameChanged(String v) {
    if (!mounted) return;
    state = state.copyWith(name: v, error: null);
  }

  void visitorTypeChanged(String? v) {
    if (!mounted) return;
    state = state.copyWith(visitorType: v, error: null);
  }

  void ageChanged(String v) {
    if (!mounted) return;
    state = state.copyWith(age: int.tryParse(v), error: null);
  }

  void daysStayChanged(String v) {
    if (!mounted) return;
    state = state.copyWith(stay: int.tryParse(v), error: null);
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

    // ✅ FIX: SIEMPRE intentamos cargar regiones.
    // Si el país no tiene, el endpoint devolverá [] y listo.
    final rid = ++_regionsReqId;
    state = state.copyWith(isLoadingRegions: true);

    try {
      final items = await loadRegionsByCode(c.code);
      if (!mounted || rid != _regionsReqId) return;

      // opcional: filtrar solo activas (por si acaso)
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
    if (!state.canSubmit) return;

    state = state.copyWith(isPosting: true, error: null);
    try {
      await submitGuest(
        name: state.name.trim(),
        countryCode: state.countryCode!,
        visitorType: state.visitorType!,
        regionId: state.selectedRegionId,
        age: state.age,
        day: state.stay,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(error: 'Ocurrió un error. Inténtalo nuevamente.');
    } finally {
      if (!mounted) return;
      state = state.copyWith(isPosting: false);
    }
  }
}
