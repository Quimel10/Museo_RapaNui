import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:easy_localization/easy_localization.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String title;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.title,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
    _listenStreams();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.audioUrl);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _listenStreams() {
    _player.durationStream.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d ?? Duration.zero);
    });

    _player.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    if (!mounted) return;
    setState(() {}); // fuerza refresco del texto Play/Pause + icono
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _player.playing;
    final totalMs = _duration.inMilliseconds.clamp(1, 24 * 60 * 60 * 1000);
    final posMs = _position.inMilliseconds.clamp(0, totalMs);

    if (_hasError) {
      return Text(
        tr('player.audio_error'), // ✅ traducible
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    if (_isLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            tr('player.loading_audio'), // ✅ traducible
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: _togglePlay,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isPlaying
                    ? tr('player.pause_audio')
                    : tr(
                        'player.play_audio',
                      ), // ✅ traducible + cambia con idioma
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            min: 0,
            max: totalMs.toDouble(),
            value: posMs.toDouble(),
            onChanged: (v) {
              final newPos = Duration(milliseconds: v.toInt());
              _player.seek(newPos);
            },
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(_position),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Text(
              _format(_duration),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
