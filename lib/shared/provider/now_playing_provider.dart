import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';

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
      descriptionHtml: descriptionHtml ?? this.descriptionHtml,
    );
  }
}

class NowPlayingNotifier extends StateNotifier<NowPlayingState> {
  final Ref ref;
  final AudioPlayerService _audio;

  StreamSubscription<PlayerState>? _psSub;

  // 🔒 serializa comandos (evita carreras)
  Future<void> _queue = Future.value();

  NowPlayingNotifier(this.ref)
    : _audio = ref.read(audioPlayerProvider),
      super(const NowPlayingState()) {
    _psSub = _audio.playerStateStream.listen((ps) {
      if (!mounted) return;
      // 👇 no rompas isBusy / metadata: solo actualiza isPlaying
      state = state.copyWith(isPlaying: ps.playing);
    });

    state = state.copyWith(isPlaying: _audio.isPlaying);
  }

  // ─────────────────────────────
  // Helpers tolerantes a PlaceEntity
  // ─────────────────────────────
  int? _id(PlaceEntity p) {
    final d = p as dynamic;
    try {
      return d.id as int?;
    } catch (_) {
      return null;
    }
  }

  String _title(PlaceEntity p) {
    final d = p as dynamic;
    try {
      return (d.titulo ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  String _subtitle(PlaceEntity p) {
    final d = p as dynamic;
    try {
      final v = (d.tipo ?? '')
          .toString(); // mejor que descCorta como "subtitle"
      return v;
    } catch (_) {
      return '';
    }
  }

  String? _audioUrl(PlaceEntity p) {
    final d = p as dynamic;
    try {
      final v = (d.audio ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = (d.audioUrl ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = (d.audio_url ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  String? _imageUrl(PlaceEntity p) {
    final d = p as dynamic;
    try {
      final v = (d.imagenHigh ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = (d.imagen ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  String? _descriptionHtml(PlaceEntity p) {
    final d = p as dynamic;
    try {
      final v = (d.descLargaHtml ?? '').toString();
      if (v.trim().isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = (d.descLarga ?? '').toString();
      if (v.trim().isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = (d.desc_larga ?? '').toString();
      if (v.trim().isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  // ─────────────────────────────
  // Lock
  // ─────────────────────────────
  Future<void> _runLocked(Future<void> Function() action) {
    _queue = _queue.then((_) async {
      if (!mounted) return;
      state = state.copyWith(isBusy: true);
      try {
        await action();
      } finally {
        if (mounted) state = state.copyWith(isBusy: false);
      }
    });
    return _queue;
  }

  // ─────────────────────────────
  // API
  // ─────────────────────────────

  /// ✅ Usado por Home/cards
  Future<void> playFromPlace(PlaceEntity place) {
    final url = (_audioUrl(place) ?? '').trim();
    if (url.isEmpty) return Future.value();

    return _runLocked(() async {
      final isSame = (state.url ?? '') == url;

      // set metadata antes de arrancar
      state = NowPlayingState(
        url: url,
        title: _title(place),
        subtitle: _subtitle(place),
        placeId: _id(place),
        place: place,
        imageUrl: _imageUrl(place),
        descriptionHtml: _descriptionHtml(place),
        isPlaying: state.isPlaying,
        isBusy: true,
      );

      if (!isSame) {
        await _audio.setUrl(url); // ✅ esperar SOLO carga
      }

      // ❌ NO await play() — si no, se “ocupa” hasta el final del track
      unawaited(_audio.play());
    });
  }

  /// ✅ COMPAT: lo llama PlaceDetails
  Future<void> playFromUrl({
    required String url,
    required String title,
    String subtitle = '',
    int? placeId,
    PlaceEntity? place,
    String? imageUrl,
    String? descriptionHtml,
  }) {
    final clean = url.trim();
    if (clean.isEmpty) return Future.value();

    return _runLocked(() async {
      final isSame = (state.url ?? '') == clean;

      state = NowPlayingState(
        url: clean,
        title: title,
        subtitle: subtitle,
        placeId: placeId,
        place: place,
        imageUrl: imageUrl,
        descriptionHtml: descriptionHtml,
        isPlaying: state.isPlaying,
        isBusy: true,
      );

      if (!isSame) {
        await _audio.setUrl(clean);
      }

      unawaited(_audio.play());
    });
  }

  /// ✅ COMPAT: llamadas viejas
  Future<void> playFromMeta({
    required String url,
    required String title,
    String subtitle = '',
    int? placeId,
    PlaceEntity? place,
    String? imageUrl,
    String? descriptionHtml,
  }) => playFromUrl(
    url: url,
    title: title,
    subtitle: subtitle,
    placeId: placeId,
    place: place,
    imageUrl: imageUrl,
    descriptionHtml: descriptionHtml,
  );

  Future<void> pause() => _runLocked(() async {
    if (_audio.isPlaying) {
      await _audio.pause(); // pause sí se puede await
    }
  });

  Future<void> resume() => _runLocked(() async {
    // ❌ no await play()
    unawaited(_audio.play());
  });

  Future<void> toggle() => _runLocked(() async {
    if (_audio.isPlaying) {
      await _audio.pause();
    } else {
      unawaited(_audio.play());
    }
  });

  Future<void> clear() => _runLocked(() async {
    await _audio.stop();
    state = const NowPlayingState();
  });

  @override
  void dispose() {
    _psSub?.cancel();
    super.dispose();
  }
}
