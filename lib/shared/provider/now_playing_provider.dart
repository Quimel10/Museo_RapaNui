import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NowPlayingState {
  final String? url;
  final String title;
  final String subtitle;
  final int? placeId;
  final bool isPlaying;

  /// 🔥 NUEVO: guardamos también la pieza completa
  final PlaceEntity? place;

  const NowPlayingState({
    this.url,
    this.title = '',
    this.subtitle = '',
    this.placeId,
    this.isPlaying = false,
    this.place,
  });

  bool get hasAudio => url != null && url!.isNotEmpty;

  NowPlayingState copyWith({
    String? url,
    String? title,
    String? subtitle,
    int? placeId,
    bool? isPlaying,
    PlaceEntity? place,
  }) {
    return NowPlayingState(
      url: url ?? this.url,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      placeId: placeId ?? this.placeId,
      isPlaying: isPlaying ?? this.isPlaying,
      place: place ?? this.place,
    );
  }
}

class NowPlayingNotifier extends StateNotifier<NowPlayingState> {
  NowPlayingNotifier() : super(const NowPlayingState());

  /// Cargamos el estado a partir de una pieza
  void setFromPlace(PlaceEntity place) {
    if (place.audio.isEmpty) return;

    state = NowPlayingState(
      url: place.audio,
      title: place.titulo,
      subtitle: place.descCorta,
      placeId: place.id,
      place: place,
      isPlaying: true,
    );
  }

  void setIsPlaying(bool value) {
    state = state.copyWith(isPlaying: value);
  }

  void clear() {
    state = const NowPlayingState();
  }
}

final nowPlayingProvider =
    StateNotifierProvider<NowPlayingNotifier, NowPlayingState>(
      (ref) => NowPlayingNotifier(),
    );
