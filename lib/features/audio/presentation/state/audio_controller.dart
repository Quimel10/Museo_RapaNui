import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AudioState {
  final String? pieceId; // pieza actual cargada
  final bool isPlaying; // player.playing
  final Duration position;
  final Duration duration;

  const AudioState({
    this.pieceId,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  AudioState copyWith({
    String? pieceId,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return AudioState(
      pieceId: pieceId ?? this.pieceId,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

final audioControllerProvider =
    StateNotifierProvider<AudioController, AudioState>((ref) {
      final controller = AudioController();
      ref.onDispose(controller.dispose);
      return controller;
    });

class AudioController extends StateNotifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

  AudioController() : super(const AudioState()) {
    _playingSub = _player.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _posSub = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _durSub = _player.durationStream.listen((dur) {
      state = state.copyWith(duration: dur ?? Duration.zero);
    });
  }

  /// Reproduce una pieza. Si es la misma pieza: togglear play/pause.
  Future<void> playOrToggle({
    required String pieceId,
    required String url,
  }) async {
    // Si es la misma pieza cargada -> toggle
    if (state.pieceId == pieceId) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    // Si es otra pieza -> cargar y reproducir
    state = state.copyWith(
      pieceId: pieceId,
      position: Duration.zero,
      duration: Duration.zero,
    );

    await _player.stop();
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    state = const AudioState();
  }

  Future<void> dispose() async {
    await _playingSub?.cancel();
    await _posSub?.cancel();
    await _durSub?.cancel();
    await _player.dispose();
  }
}
