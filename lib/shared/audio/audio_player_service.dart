// lib/shared/audio/audio_player_service.dart
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// ✅ NO autoDispose. Un solo servicio vivo en toda la app.
final audioPlayerProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 🔹 Modelo unificado de posición (para sliders PRO)
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  const PositionData(this.position, this.bufferedPosition, this.duration);
}

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  AudioHandler? _handler;

  String? _currentUrl;

  /// ✅ Lock SOLO para cambios de source (setUrl)
  Future<void> _setUrlQueue = Future.value();

  /// ✅ Track: si hay un setUrl en curso, play() debe esperar
  Future<void>? _pendingSetUrl;

  // ─────────────────────────────
  // 🔹 LEGACY GETTERS (NO BORRAR)
  // ─────────────────────────────
  AudioPlayer get player => _player;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // ─────────────────────────────
  // 🔥 API MODERNA
  // ─────────────────────────────
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, buffered, duration) =>
            PositionData(position, buffered, duration ?? Duration.zero),
      );

  AudioPlayerService() {
    // ✅ Prewarm handler para que exista antes del primer play
    unawaited(_ensureHandler());
  }

  // ─────────────────────────────
  // 🎛️ AudioService init (notification/lockscreen)
  // ─────────────────────────────
  Future<AudioHandler> _ensureHandler() async {
    if (_handler != null) return _handler!;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _handler = await AudioService.init(
      builder: () => _AppAudioHandler(_player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'cl.unb.museorapanui.audio',
        androidNotificationChannelName: 'Museo RapaNui',

        // ✅ Si es ongoing, STOP_FOREGROUND_ON_PAUSE debe ser true (regla del package)
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,

        androidShowNotificationBadge: false,

        // opcional: si quieres icono custom en notificación
        // androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );

    return _handler!;
  }

  Future<void> _publishMediaItem({
    required String url,
    required String title,
    String subtitle = '',
    String? artUri,
  }) async {
    final h = await _ensureHandler();
    if (h is _AppAudioHandler) {
      h.setMediaItem(
        MediaItem(
          id: url,
          title: title.trim().isEmpty ? 'Audio' : title.trim(),
          artist: subtitle.trim().isEmpty ? null : subtitle.trim(),
          artUri: (artUri == null || artUri.trim().isEmpty)
              ? null
              : Uri.tryParse(artUri.trim()),
          // duration se setea luego cuando just_audio la conoce
        ),
      );
    }
  }

  // ─────────────────────────────
  // 🎵 API pública
  // ─────────────────────────────

  /// ✅ Serializado (setUrl seguido rompe si se pisan)
  /// - Publica MediaItem ANTES (para que la notificación tenga metadata)
  /// - Cambia source en el player (esto “tapa” la anterior)
  Future<void> setUrl(
    String url, {
    String title = 'Audio',
    String subtitle = '',
    String? artUri,
  }) {
    final clean = url.trim();
    if (clean.isEmpty) return Future.value();

    final completer = Completer<void>();

    final task = () async {
      await _ensureHandler();

      await _publishMediaItem(
        url: clean,
        title: title,
        subtitle: subtitle,
        artUri: artUri,
      );

      // ✅ Si es el mismo audio, no resetees decoder
      if (_currentUrl == clean) return;

      _currentUrl = clean;

      // ✅ Cambiar source: esto detiene lo anterior y prepara lo nuevo
      await _player.setUrl(clean);
    };

    _setUrlQueue = _setUrlQueue.then((_) async {
      try {
        _pendingSetUrl = task();
        await _pendingSetUrl;
        _pendingSetUrl = null;

        if (!completer.isCompleted) completer.complete();
      } catch (e, st) {
        _pendingSetUrl = null;
        if (!completer.isCompleted) completer.completeError(e, st);
      }
    });

    return completer.future;
  }

  /// ✅ IMPORTANTE:
  /// - Si setUrl está corriendo, esperamos.
  /// - Usamos handler.play() para que la notificación salga inmediatamente.
  Future<void> play() async {
    // si justo le diste play mientras setUrl está cargando, espera
    final pending = _pendingSetUrl;
    if (pending != null) {
      await pending;
    }

    final h = await _ensureHandler();
    await h.play();
  }

  Future<void> pause() async {
    final h = await _ensureHandler();
    await h.pause();
  }

  Future<void> stop() async {
    final h = await _ensureHandler();
    await h.stop();
  }

  Future<void> seek(Duration position) async {
    final h = await _ensureHandler();
    await h.seek(position);
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}

/// =======================================================
/// ✅ AudioHandler real (esto crea la notificación)
/// =======================================================
class _AppAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  StreamSubscription<PlayerState>? _psSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  _AppAudioHandler(this._player) {
    // ✅ Estado de reproducción -> playbackState (notificación)
    _psSub = _player.playerStateStream.listen((ps) {
      playbackState.add(_mapPlaybackState(ps));
    });

    // ✅ Posición -> updatePosition (THROTTLE para evitar ANR)
    _posSub = _player.positionStream
        .throttleTime(const Duration(milliseconds: 500), trailing: true)
        .listen((pos) {
          final current = playbackState.valueOrNull;
          if (current == null) return;
          playbackState.add(current.copyWith(updatePosition: pos));
        });

    // ✅ Duración -> MediaItem.duration (si no, algunos paneles quedan 0:00)
    _durSub = _player.durationStream.listen((d) {
      final item = mediaItem.valueOrNull;
      if (item == null) return;
      mediaItem.add(item.copyWith(duration: d));
    });
  }

  void setMediaItem(MediaItem item) => mediaItem.add(item);

  PlaybackState _mapPlaybackState(PlayerState ps) {
    final playing = ps.playing;

    final processingState = switch (ps.processingState) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };

    // ✅ Controles (sin stop para evitar “cuadrado”)
    final controls = <MediaControl>[
      MediaControl.rewind,
      playing ? MediaControl.pause : MediaControl.play,
      MediaControl.fastForward,
    ];

    return PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.rewind,
        MediaAction.fastForward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  // Acciones desde notificación / lockscreen
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> rewind() async {
    final p = _player.position - const Duration(seconds: 10);
    await _player.seek(p < Duration.zero ? Duration.zero : p);
  }

  @override
  Future<void> fastForward() async {
    final d = _player.duration ?? Duration.zero;
    final p = _player.position + const Duration(seconds: 10);
    await _player.seek((d == Duration.zero) ? p : (p > d ? d : p));
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  Future<void> disposeHandler() async {
    await _psSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
  }
}
