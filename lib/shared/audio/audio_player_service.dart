import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// ✅ NO autoDispose. Un solo AudioPlayer vivo en toda la app.
final audioPlayerProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 🔹 Modelo unificado de posición
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData(this.position, this.bufferedPosition, this.duration);
}

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;

  /// Serializa cambios de source
  Future<void> _queue = Future.value();

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
  // 🔥 API MODERNA (SOURCE OF TRUTH)
  // ─────────────────────────────

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, buffered, duration) =>
            PositionData(position, buffered, duration ?? Duration.zero),
      );

  // ─────────────────────────────
  // 🔒 Lock helpers
  // ─────────────────────────────

  Future<T> _runLocked<T>(Future<T> Function() action) {
    final c = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        final r = await action();
        if (!c.isCompleted) c.complete(r);
      } catch (e, st) {
        if (!c.isCompleted) c.completeError(e, st);
      }
    });
    return c.future;
  }

  // ─────────────────────────────
  // 🎵 API pública
  // ─────────────────────────────

  Future<void> setUrl(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return Future.value();

    return _runLocked(() async {
      if (_currentUrl == clean) return;
      _currentUrl = clean;
      await _player.setUrl(clean);
    });
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() {
    return _runLocked(() async {
      await _player.stop();
    });
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
