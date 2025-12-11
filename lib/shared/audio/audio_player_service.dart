import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Proveedor global del servicio de audio
final audioPlayerProvider = Provider<AudioPlayerService>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return AudioPlayerService(player);
});

class AudioPlayerService {
  AudioPlayerService(this._player);

  final AudioPlayer _player;
  String? _currentUrl;

  // Streams para el mini-player y full-player
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  /// Si la URL cambia se carga desde 0, si es la misma se reanuda.
  Future<void> playOrResume(String url) async {
    if (_currentUrl != url) {
      _currentUrl = url;
      await _player.stop();
      await _player.setUrl(url);
      await _player.seek(Duration.zero);
    }
    await _player.play();
  }

  /// Pausar sin perder la posición
  Future<void> pause() => _player.pause();

  /// Detener completamente (sin mantener posición)
  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  /// Saltar hacia adelante (por ejemplo 10 segundos)
  Future<void> skipForward(Duration offset) async {
    final current = _player.position;
    final total = _player.duration;

    var target = current + offset;
    if (total != null && target > total) {
      target = total;
    }
    if (target < Duration.zero) target = Duration.zero;

    await _player.seek(target);
  }

  /// Saltar hacia atrás (por ejemplo 10 segundos)
  Future<void> skipBackward(Duration offset) async {
    final current = _player.position;
    var target = current - offset;
    if (target < Duration.zero) target = Duration.zero;
    await _player.seek(target);
  }
}
