import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';

class NowPlayingState {
  final String? url;
  final String title;
  final String subtitle;
  final int? placeId;

  /// ✅ La UI NO debe depender de esto para saber si suena,
  /// pero lo mantenemos para textos/consistencia.
  final bool isPlaying;

  final String? imageUrl;
  final String? descriptionHtml;
  final PlaceEntity? place;

  const NowPlayingState({
    this.url,
    this.title = '',
    this.subtitle = '',
    this.placeId,
    this.isPlaying = false,
    this.imageUrl,
    this.descriptionHtml,
    this.place,
  });

  bool get hasAudio => url != null && url!.trim().isNotEmpty;

  NowPlayingState copyWith({
    String? url,
    String? title,
    String? subtitle,
    int? placeId,
    bool? isPlaying,
    String? imageUrl,
    String? descriptionHtml,
    PlaceEntity? place,
  }) {
    return NowPlayingState(
      url: url ?? this.url,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      placeId: placeId ?? this.placeId,
      isPlaying: isPlaying ?? this.isPlaying,
      imageUrl: imageUrl ?? this.imageUrl,
      descriptionHtml: descriptionHtml ?? this.descriptionHtml,
      place: place ?? this.place,
    );
  }
}

class NowPlayingNotifier extends StateNotifier<NowPlayingState> {
  NowPlayingNotifier(this._audio) : super(const NowPlayingState()) {
    _bindAudio();
  }

  final AudioPlayerService _audio;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  void _bindAudio() {
    // ✅ Sync: si el audio cambia, actualizamos el state
    _playingSub = _audio.playingStream.listen((playing) {
      if (!state.hasAudio) return;
      if (state.isPlaying != playing) {
        state = state.copyWith(isPlaying: playing);
      }
    });

    // ✅ Sync: si terminó (completed) -> isPlaying false
    _playerStateSub = _audio.playerStateStream.listen((ps) {
      if (!state.hasAudio) return;
      if (ps.processingState == ProcessingState.completed) {
        if (state.isPlaying != false) {
          state = state.copyWith(isPlaying: false);
        }
      }
    });
  }

  /// 🎧 Home
  Future<void> playFromPlace(PlaceEntity place) async {
    if (place.audio.trim().isEmpty) return;

    final cover = place.imagenHigh.trim().isNotEmpty
        ? place.imagenHigh.trim()
        : null;

    state = NowPlayingState(
      url: place.audio.trim(),
      title: place.titulo,
      subtitle: place.descCorta,
      placeId: place.id,
      place: place,
      isPlaying: true,
      imageUrl: cover,
      descriptionHtml: null,
    );

    await _audio.playOrResume(place.audio.trim());
  }

  /// 🎧 Details / otros contextos
  Future<void> playFromUrl({
    required String url,
    required String title,
    String subtitle = '',
    int? placeId,
    PlaceEntity? place,
    String? imageUrl,
    String? descriptionHtml,
  }) async {
    final clean = url.trim();
    if (clean.isEmpty) return;

    final coverFromPlace = (place != null && place.imagenHigh.trim().isNotEmpty)
        ? place.imagenHigh.trim()
        : null;

    final coverFinal =
        coverFromPlace ??
        (imageUrl?.trim().isNotEmpty == true ? imageUrl!.trim() : null);

    state = NowPlayingState(
      url: clean,
      title: title,
      subtitle: subtitle,
      placeId: placeId,
      place: place,
      isPlaying: true,
      imageUrl: coverFinal,
      descriptionHtml: (descriptionHtml?.trim().isNotEmpty == true)
          ? descriptionHtml!.trim()
          : null,
    );

    await _audio.playOrResume(clean);
  }

  Future<void> pause() async {
    await _audio.pause();
    if (state.isPlaying != false) {
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> resume() async {
    final url = state.url?.trim();
    if (url == null || url.isEmpty) return;

    await _audio.playOrResume(url);
    if (state.isPlaying != true) {
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> toggle() async {
    if (_audio.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> clear() async {
    await _audio.stop();
    state = const NowPlayingState();
  }

  /// ✅ COMPAT: si algún archivo llama stop(), que no rompa
  Future<void> stop() async => clear();

  @override
  void dispose() {
    _playingSub?.cancel();
    _playerStateSub?.cancel();
    super.dispose();
  }
}

final nowPlayingProvider =
    StateNotifierProvider<NowPlayingNotifier, NowPlayingState>((ref) {
      final audio = ref.read(audioPlayerProvider);
      return NowPlayingNotifier(audio);
    });
