import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/geo/auth_geo_datasource_provider.dart';

import 'guest_notifier.dart';
import 'guest_state.dart';

String _normalizeVisitorType(String raw) {
  final v = raw.trim().toLowerCase();

  // Acepta variaciones típicas y las deja “bonitas” para Analytics
  if (v.contains('local')) return 'Local (RapaNui)';
  if (v.contains('continental')) return 'Continental';
  if (v.contains('extranj')) return 'Extranjero';

  if (raw.trim().isNotEmpty) return raw.trim();

  // fallback seguro (no debería usarse si forzamos a seleccionar)
  return 'Continental';
}

final guestFormProvider =
    StateNotifierProvider.autoDispose<GuestFormNotifier, GuestFormState>((ref) {
      final geo = ref.read(authGeoDataSourceProvider);
      final auth = ref.read(authProvider.notifier);

      return GuestFormNotifier(
        loadCountries: () => geo.countries(),
        loadRegionsByCode: (code) => geo.regionsByCountryCode(code),
        submitGuest:
            ({
              required String name,
              required String countryCode,
              required String visitorType,
              int? regionId,
              int? day,
              int? age,
            }) async {
              final normalizedVisitorType = _normalizeVisitorType(visitorType);

              final guest = Guest(
                name: name.trim(),
                countryCode: countryCode.trim().toUpperCase(),
                visitorType: normalizedVisitorType,
                regionId: regionId,
                daysStay: day,
                age: age,
              );

              await auth.guestUser(guest);
            },
      );
    });
