import 'package:disfruta_antofagasta/features/auth/infrastructure/datasources/auth_datasource_impl.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'register_notifier.dart';
import 'register_state.dart';

// Si ya tienes este provider en otro archivo, usa ese
final geoDataSourceProvider = Provider<AuthDataSourceImpl>((ref) {
  final storage = ref.read(keyValueStorageServiceProvider);

  return AuthDataSourceImpl(keyValueStorageService: storage);
});

final registerFormProvider =
    StateNotifierProvider.autoDispose<RegisterFormNotifier, RegisterFormState>((
      ref,
    ) {
      final geo = ref.read(geoDataSourceProvider);
      final registerCb = ref
          .read(authProvider.notifier)
          .registerUser; // <-- ya existe en tu AuthNotifier

      return RegisterFormNotifier(
        loadCountries: geo.countries,
        loadRegions: geo.regions,
        registerUserCallback: registerCb,
      );
    });
