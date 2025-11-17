import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';
import 'package:disfruta_antofagasta/features/auth/infrastructure/datasources/auth_datasource_impl.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'guest_notifier.dart';
import 'guest_state.dart';

// Provider del datasource (ajusta si ya lo tienes)
final geoDataSourceProvider = Provider<AuthDataSourceImpl>((ref) {
  final storage = ref.read(keyValueStorageServiceProvider);

  return AuthDataSourceImpl(
    keyValueStorageService: storage,
  ); // si necesita baseUrl ya lo tienes en Environment
});

final guestFormProvider =
    StateNotifierProvider.autoDispose<GuestFormNotifier, GuestFormState>((ref) {
      final geo = ref.read(geoDataSourceProvider);
      final auth = ref.read(authProvider.notifier); // tu AuthNotifier

      return GuestFormNotifier(
        loadCountries: geo.countries,
        loadRegions: geo.regions,
        submitGuest:
            ({
              required String name,
              required String countryCode,
              int? regionId,
              int? day,
              int? age,
            }) async {
              final Guest authRes = Guest(
                name: name,
                country: countryCode,
                region: regionId,
                day: day,
                age: age,
              );

              await auth.guestUser(authRes);
            },
      );
    });
