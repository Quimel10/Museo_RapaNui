import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioPlayerProvider = ChangeNotifierProvider<AudioPlayerService>((ref) {
  final svc = AudioPlayerService();
  ref.onDispose(() => svc.dispose());
  return svc;
});

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  Duration _position = Duration.zero;
  Duration? _duration;

  Duration get position => _position;
  Duration? get duration => _duration;
  bool get isPlaying => _player.playing;

  // ✅ Streams para UI
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;

  PlayerState get playerState => _player.playerState;

  AudioPlayerService() {
    _playingSub = _player.playingStream.listen((_) => notifyListeners());

    _posSub = _player.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });

    _durSub = _player.durationStream.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _stateSub = _player.playerStateStream.listen((_) => notifyListeners());
  }

  String? get currentUrl => _player.audioSource is UriAudioSource
      ? (_player.audioSource as UriAudioSource).uri.toString()
      : null;

  /// ✅ Carga url si cambia, si es la misma reanuda.
  /// ✅ Si quedó en completed, vuelve a 0 y reproduce.
  Future<void> playOrResume(String url) async {
    final clean = url.trim();
    if (clean.isEmpty) return;

    try {
      final cur = currentUrl;

      // Mismo URL: solo play (si completed -> seek(0))
      if (cur != null && cur == clean) {
        if (_player.playerState.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
        notifyListeners();
        return;
      }

      // URL distinta: detener + cargar nuevo
      await _player.stop();
      _position = Duration.zero;
      _duration = null;
      notifyListeners();

      await _player.setUrl(clean);
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Audio playOrResume error: $e');
    }
  }

  Future<void> play() async {
    try {
      if (_player.playerState.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Audio play error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Audio pause error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _position = Duration.zero;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Audio stop error: $e');
    }
  }

  Future<void> seek(Duration target) async {
    try {
      await _player.seek(target);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Audio seek error: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _playingSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _stateSub?.cancel();
    await _player.dispose();
    super.dispose();
  }
}
