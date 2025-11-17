import 'package:disfruta_antofagasta/features/places/presentation/provider/place_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:disfruta_antofagasta/features/places/presentation/state/place_state.dart';
import 'package:disfruta_antofagasta/features/places/presentation/state/place_notifier.dart';

final placeProvider = StateNotifierProvider<PlaceNotifier, PlaceState>((ref) {
  final repo = ref.watch(placeRepositoryProvider);
  final notifier = PlaceNotifier(repository: repo);

  // 1) Carga inicial con el idioma actual
  final initialLang = ref.read(languageProvider);
  notifier.initForLang(initialLang);

  // 2) Cuando el idioma cambie, recargamos SIN recrear el notifier
  ref.listen<String>(languageProvider, (prev, next) {
    notifier.initForLang(next);
  });

  return notifier;
});
