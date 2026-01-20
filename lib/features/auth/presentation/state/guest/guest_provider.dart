import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/features/auth/domain/entities/guest.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/geo/auth_geo_datasource_provider.dart';

import 'guest_notifier.dart';
import 'guest_state.dart';

/// ✅ Normaliza cualquier valor recibido (viejo o nuevo) a KEYS canónicos
/// que deben coincidir con WP/DB.
///
/// Keys canónicos:
/// - local_rapanui
/// - local_no_rapanui
/// - continental
/// - extranjero
String _normalizeVisitorTypeKey(String raw) {
  final v = raw.trim().toLowerCase();
  if (v.isEmpty) return 'continental';

  // ya canónico
  if (v == 'local_rapanui' ||
      v == 'local_no_rapanui' ||
      v == 'continental' ||
      v == 'extranjero') {
    return v;
  }

  // compat con keys antiguas de la app
  if (v == 'rapanui') return 'local_rapanui';
  if (v == 'foreign') return 'extranjero';

  // compat con textos (por si quedaron guardados)
  if (v.contains('no rapanui') || v.contains('no-rapanui')) {
    return 'local_no_rapanui';
  }
  if (v.contains('rapanui')) return 'local_rapanui';
  if (v.contains('continental')) return 'continental';
  if (v.contains('extranj')) return 'extranjero';
  if (v.contains('visitante')) return 'extranjero';

  return 'continental';
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
              final visitorTypeKey = _normalizeVisitorTypeKey(visitorType);

              final guest = Guest(
                name: name.trim(),
                countryCode: countryCode.trim().toUpperCase(),
                visitorType: visitorTypeKey, // ✅ ahora guardamos KEY, no texto
                regionId: regionId,
                daysStay: day,
                age: age,
              );

              await auth.guestUser(guest);
            },
      );
    });
