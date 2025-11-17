import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_notifier.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_state.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.read(authRepositoryProvider); // ✅ lee el REPO
  final storage = ref.read(keyValueStorageServiceProvider);
  return AuthNotifier(authRepository: repo, keyValueStorageService: storage);
});
