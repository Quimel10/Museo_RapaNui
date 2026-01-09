import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/geo/auth_geo_datasource_provider.dart';

import 'register_notifier.dart';
import 'register_state.dart';

final registerFormProvider =
    StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>((
      ref,
    ) {
      final geo = ref.read(authGeoDataSourceProvider);
      final registerCb = ref.read(authProvider.notifier).registerUser;

      return RegisterFormNotifier(
        loadCountries: () => geo.countries(),
        loadRegionsByCode: (code) => geo.regionsByCountryCode(code),
        registerUserCallback: registerCb,
      );
    });
