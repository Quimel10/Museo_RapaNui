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
  final List<String> images;
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
    this.images = const <String>[],
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

  // ✅ Guard para evitar loops cuando hacemos pause/seek en completed
  bool _handlingCompleted = false;

  NowPlayingNotifier(this.ref)
    : _audio = ref.read(audioPlayerProvider),
      super(const NowPlayingState()) {
    _psSub = _audio.playerStateStream.listen((ps) {
      if (!mounted) return;

      // 1) Siempre reflejar "playing"
      state = state.copyWith(isPlaying: ps.playing);

      // 2) Si termina el audio -> NO reanudar
      if (ps.processingState == ProcessingState.completed) {
        // Evita doble ejecución si el stream emite varias veces completed
        if (_handlingCompleted) return;
        _handlingCompleted = true;

        // UI: queda en pausa y no busy
        state = state.copyWith(isPlaying: false, isBusy: false);

        // Player: aseguramos pausa/stop lógico + volver a 0 SIN reproducir
        unawaited(() async {
          try {
            // por seguridad: fuerza a que NO siga reproduciendo
            await _audio.pause();

            // vuelve al inicio
            await _audio.seek(Duration.zero);
          } catch (_) {
            // no-op
          } finally {
            // suelta el guard en el próximo microtask
            Future.microtask(() => _handlingCompleted = false);
          }
        }());
      }

      // 3) Libera busy cuando el player ya respondió
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

    if (out.isEmpty) addOne(fallback);

    return out;
  }

  bool _isCompletedOrAtEnd() {
    final ps = _audio.player.playerState;
    if (ps.processingState == ProcessingState.completed) return true;

    final d = _audio.duration;
    if (d == null || d == Duration.zero) return false;

    final pos = _audio.position;
    return (d - pos) <= const Duration(milliseconds: 200);
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
      images: const <String>[],
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
    List<String> images = const <String>[],
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
      images: imgs,
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
      } else {
        // ✅ Si es el mismo audio y estaba al final: vuelve a 0
        // (pero NO reproduce hasta que el usuario lo pida; play() lo hará)
        if (_isCompletedOrAtEnd()) {
          await _audio.seek(Duration.zero);
        }
      }

      await _audio.play();
    } finally {
      if (mounted) state = state.copyWith(isBusy: false);
    }
  }

  Future<void> toggle() async {
    if (_audio.isPlaying) {
      await _audio.pause();
      return;
    }

    // Si estaba terminado, vuelve al inicio ANTES de play
    if (_isCompletedOrAtEnd()) {
      await _audio.seek(Duration.zero);
    }

    await _audio.play();
  }

  Future<void> togglePlayPause() => toggle();

  Future<void> resume() async {
    if (_isCompletedOrAtEnd()) {
      await _audio.seek(Duration.zero);
    }
    await _audio.play();
  }

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
