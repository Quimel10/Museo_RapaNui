// SplashGate.dart
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashGate extends ConsumerWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Forzamos a evaluar authProvider para que corra checkAuthStatus en el init
    ref.watch(authProvider);
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
