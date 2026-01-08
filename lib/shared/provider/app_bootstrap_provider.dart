import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppBootstrapState {
  final bool isLoading;
  final String message;

  const AppBootstrapState({this.isLoading = true, this.message = 'Cargando…'});

  AppBootstrapState copyWith({bool? isLoading, String? message}) {
    return AppBootstrapState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
    );
  }
}

class AppBootstrapNotifier extends StateNotifier<AppBootstrapState> {
  AppBootstrapNotifier() : super(const AppBootstrapState());

  bool _ran = false;

  Future<void> runBootstrap() async {
    if (_ran) return;
    _ran = true;

    final start = DateTime.now();
    const minVisible = Duration(milliseconds: 900);

    try {
      state = state.copyWith(isLoading: true, message: 'Cargando…');

      // ✅ Si aquí tienes inicializaciones reales, ponlas.
      // Si no, igual mantenemos el mínimo visible.
      // await tuInitReal();

      final elapsed = DateTime.now().difference(start);
      final remaining = minVisible - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final appBootstrapProvider =
    StateNotifierProvider<AppBootstrapNotifier, AppBootstrapState>(
      (ref) => AppBootstrapNotifier(),
    );
