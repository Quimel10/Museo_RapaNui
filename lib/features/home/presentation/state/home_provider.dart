import 'package:disfruta_antofagasta/features/home/presentation/provider/home_repository_provider.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_notifier.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_state.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  final notifier = HomeNotifier(repository: repository);

  // Inicializa con el idioma actual
  final initialLang = ref.read(languageProvider);
  notifier.init(initialLang);

  // Reacciona a cambios de idioma sin recrear el notifier
  ref.listen<String>(languageProvider, (prev, next) {
    notifier.init(next);
  });

  return notifier;
});
