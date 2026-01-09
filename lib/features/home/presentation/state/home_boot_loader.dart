import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeBootLoaderState {
  final bool isLoading;
  final String message;

  const HomeBootLoaderState({this.isLoading = false, this.message = ''});

  HomeBootLoaderState copyWith({bool? isLoading, String? message}) {
    return HomeBootLoaderState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
    );
  }
}

final homeBootLoaderProvider =
    StateNotifierProvider<HomeBootLoaderNotifier, HomeBootLoaderState>(
      (ref) => HomeBootLoaderNotifier(),
    );

class HomeBootLoaderNotifier extends StateNotifier<HomeBootLoaderState> {
  HomeBootLoaderNotifier() : super(const HomeBootLoaderState());

  void show([String msg = 'Cargando contenido…']) {
    state = state.copyWith(isLoading: true, message: msg);
  }

  void hide() {
    state = state.copyWith(isLoading: false, message: '');
  }

  void setMessage(String msg) {
    state = state.copyWith(message: msg);
  }
}
