// lib/shared/provider/now_playing_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/audio_player_service.dart';
import '../../features/home/domain/entities/place.dart';

final nowPlayingProvider =
    StateNotifierProvider<NowPlayingNotifier, NowPlayingState>(
      (ref) => NowPlayingNotifier(ref),
    );

class NowPlayingState {
  final String? url;
  final String title;
  final String subtitle;
  final int? placeId;

  final bool isPlaying;
  final bool isBusy;

  final PlaceEntity? place;
  final String? imageUrl;
  final List<String> images; // ✅ NUEVO: galería completa para el player
  final String? descriptionHtml;

  const NowPlayingState({
    this.url,
    this.title = '',
    this.subtitle = '',
    this.placeId,
    this.isPlaying = false,
    this.isBusy = false,
    this.place,
    this.imageUrl,
    this.images = const <String>[], // ✅ default seguro
    this.descriptionHtml,
  });

  bool get hasAudio => url != null && url!.trim().isNotEmpty;

  NowPlayingState copyWith({
    String? url,
    String? title,
    String? subtitle,
    int? placeId,
    bool? isPlaying,
    bool? isBusy,
    PlaceEntity? place,
    String? imageUrl,
    List<String>? images,
    String? descriptionHtml,
  }) {
    return NowPlayingState(
      url: url ?? this.url,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      placeId: placeId ?? this.placeId,
      isPlaying: isPlaying ?? this.isPlaying,
      isBusy: isBusy ?? this.isBusy,
      place: place ?? this.place,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      descriptionHtml: descriptionHtml ?? this.descriptionHtml,
    );
  }
}

class NowPlayingNotifier extends StateNotifier<NowPlayingState> {
  final Ref ref;
  final AudioPlayerService _audio;

  StreamSubscription<PlayerState>? _psSub;

  NowPlayingNotifier(this.ref)
    : _audio = ref.read(audioPlayerProvider),
      super(const NowPlayingState()) {
    // Fuente única de verdad para el estado playing/busy
    _psSub = _audio.playerStateStream.listen((ps) {
      if (!mounted) return;

      state = state.copyWith(isPlaying: ps.playing);

      // ✅ Libera busy cuando el player ya respondió
      if (state.isBusy) {
        final s = ps.processingState;
        if (s == ProcessingState.loading ||
            s == ProcessingState.buffering ||
            s == ProcessingState.ready ||
            s == ProcessingState.completed) {
          state = state.copyWith(isBusy: false);
        }
      }
    });

    state = state.copyWith(isPlaying: _audio.isPlaying);
  }

  // ------------------------------------------------------------
  // Helpers internos
  // ------------------------------------------------------------
  List<String> _sanitizeImages(List<String>? input, {String? fallback}) {
    final seen = <String>{};
    final out = <String>[];

    void addOne(String? u) {
      final x = (u ?? '').trim();
      if (x.isEmpty) return;
      if (seen.add(x)) out.add(x);
    }

    if (input != null) {
      for (final u in input) {
        addOne(u);
      }
    }

    // fallback (si no vienen imágenes)
    if (out.isEmpty) addOne(fallback);

    return out;
  }

  // ============================================================
  // ✅ API COMPATIBLE CON TU UI ACTUAL
  // ============================================================

  Future<void> playFromPlace(PlaceEntity place) async {
    final url = place.audio.trim();
    if (url.isEmpty) return;

    final hero = (place.imagenHigh?.isNotEmpty == true)
        ? place.imagenHigh
        : place.imagen;

    await playFromUrl(
      url: url,
      title: place.titulo,
      subtitle: place.tipo,
      placeId: place.id,
      place: place,
      imageUrl: hero,
      images: const [], // si desde aquí no pasas lista, queda con fallback hero
      descriptionHtml: (place.descLargaHtml?.isNotEmpty == true)
          ? place.descLargaHtml
          : place.descLarga,
    );
  }

  Future<void> playFromUrl({
    required String url,
    required String title,
    String subtitle = '',
    int? placeId,
    PlaceEntity? place,
    String? imageUrl,
    List<String> images = const <String>[], // ✅ NUEVO
    String? descriptionHtml,
  }) async {
    final clean = url.trim();
    if (clean.isEmpty) return;

    final isSame = (state.url ?? '') == clean;

    final imgs = _sanitizeImages(images, fallback: imageUrl);

    state = state.copyWith(
      url: clean,
      title: title,
      subtitle: subtitle,
      placeId: placeId,
      place: place,
      imageUrl: imageUrl,
      images: imgs, // ✅ guarda la galería
      descriptionHtml: descriptionHtml,
      isBusy: true,
    );

    try {
      if (!isSame) {
        await _audio.setUrl(
          clean,
          title: title,
          subtitle: subtitle,
          artUri: imageUrl,
        );
      }

      await _audio.play();
    } finally {
      if (mounted) state = state.copyWith(isBusy: false);
    }
  }

  Future<void> toggle() async {
    if (_audio.isPlaying) {
      await _audio.pause();
    } else {
      await _audio.play();
    }
  }

  // ✅ Alias por compatibilidad (por si algún widget viejo lo llama)
  Future<void> togglePlayPause() => toggle();

  /// usados por now_playing_player.dart / otros
  Future<void> resume() => _audio.play();
  Future<void> pause() => _audio.pause();

  Future<void> rewind10() async {
    final current = _audio.position;
    final target = current - const Duration(seconds: 10);
    await _audio.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> forward10() async {
    final current = _audio.position;
    final d = _audio.duration ?? Duration.zero;

    final target = current + const Duration(seconds: 10);
    if (d == Duration.zero) {
      await _audio.seek(target);
      return;
    }

    await _audio.seek(target > d ? d : target);
  }

  Future<void> clear() async {
    await _audio.stop();
    state = const NowPlayingState();
  }

  @override
  void dispose() {
    _psSub?.cancel();
    super.dispose();
  }
}
