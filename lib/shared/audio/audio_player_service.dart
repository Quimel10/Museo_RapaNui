import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// ✅ NO autoDispose. Un solo AudioPlayer vivo en toda la app.
final audioPlayerProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  String? _currentUrl;

  /// Serializa operaciones que cambian el source (setUrl/stop).
  Future<void> _queue = Future.value();

  AudioPlayer get player => _player;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

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

  /// ✅ Setea URL solo si cambió. (Esto sí va en cola)
  Future<void> setUrl(String url) {
    final clean = url.trim();
    if (clean.isEmpty) return Future.value();

    return _runLocked(() async {
      if (_currentUrl == clean) return;
      _currentUrl = clean;

      // setUrl ya prepara todo
      await _player.setUrl(clean);
    });
  }

  /// ✅ Play NO debe quedar “bloqueado” por cola si ya está preparado.
  /// Aun así, si viene justo después de setUrl, igual funciona.
  Future<void> play() async {
    // No lo meto en cola para no “perder” taps de pausa/play.
    await _player.play();
  }

  /// ✅ Pause real (no stop). NO lo metas en cola.
  Future<void> pause() async {
    await _player.pause();
  }

  /// Stop sí resetea (esto sí conviene en cola)
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
