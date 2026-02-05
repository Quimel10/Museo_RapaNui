import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/domain/entities/country.dart';
import 'package:disfruta_antofagasta/features/auth/domain/entities/region.dart';

import 'guest_state.dart';

typedef LoadCountries = Future<List<Country>> Function();
typedef LoadRegionsByCode = Future<List<Region>> Function(String code);

typedef SubmitGuest =
    Future<void> Function({
      required String name,
      required String countryCode,
      required String visitorType,
      int? regionId,
      int? day,
      int? age,
    });

class GuestFormNotifier extends StateNotifier<GuestFormState> {
  final LoadCountries loadCountries;
  final LoadRegionsByCode loadRegionsByCode;
  final SubmitGuest submitGuest;

  int _countriesReqId = 0;
  int _regionsReqId = 0;

  GuestFormNotifier({
    required this.loadCountries,
    required this.loadRegionsByCode,
    required this.submitGuest,
  }) : super(const GuestFormState());

  bool _isLocalVisitor(String? v) =>
      v == 'local_rapanui' || v == 'local_no_rapanui';

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

  void nameChanged(String v) =>
      state = state.copyWith(name: v, clearError: true);

  void ageChanged(String v) {
    final x = int.tryParse(v.trim());
    state = state.copyWith(age: x, clearError: true);
  }

  void daysStayChanged(String v) {
    final x = int.tryParse(v.trim());
    state = state.copyWith(stay: x, clearError: true);
  }

  void visitorTypeChanged(String v) {
    final willDisableStay = _isLocalVisitor(v);

    state = state.copyWith(
      visitorType: v,
      // ✅ si pasa a local, borramos stay
      stay: willDisableStay ? null : state.stay,
      clearError: true,
    );
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
      final cc = state.selectedCountry!.code.trim().toUpperCase();
      final isLocal = _isLocalVisitor(state.visitorType);

      await submitGuest(
        name: state.name.trim(),
        countryCode: cc,
        visitorType: state.visitorType!.trim(),
        regionId: state.needsRegion ? state.selectedRegionId : null,
        // ✅ local => no mandar días
        day: isLocal ? null : state.stay,
        age: state.age,
      );

      state = state.copyWith(isPosting: false);
    } catch (_) {
      state = state.copyWith(
        isPosting: false,
        error: 'No pudimos ingresar como invitado.',
      );
    }
  }
}
