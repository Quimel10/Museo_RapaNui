// lib/shared/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    final notifier = ref.read(nowPlayingProvider.notifier);

    if (!nowPlaying.hasAudio) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                nowPlaying.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                nowPlaying.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 32,
                color: nowPlaying.isBusy ? Colors.white38 : Colors.white,
              ),
              onPressed: nowPlaying.isBusy
                  ? null
                  : () async {
                      await notifier.togglePlayPause();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class FullPlayerSheet extends ConsumerWidget {
  const FullPlayerSheet({super.key});

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    final audio = ref.watch(audioPlayerProvider);
    final notifier = ref.read(nowPlayingProvider.notifier);

    final dur = audio.duration ?? Duration.zero;
    final pos = audio.position;

    final maxMs = dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds;
    final valueMs = pos.inMilliseconds.clamp(0, maxMs).toDouble();

    return Column(
      children: [
        Text(
          nowPlaying.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        // ✅ Slider SIEMPRE blanco (adiós naranja)
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white24,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: valueMs,
            max: maxMs.toDouble(),
            onChanged: (v) => audio.seek(Duration(milliseconds: v.toInt())),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt(pos), style: const TextStyle(color: Colors.white70)),
            Text(_fmt(dur), style: const TextStyle(color: Colors.white70)),
          ],
        ),

        const SizedBox(height: 8),

        IconButton(
          iconSize: 72,
          icon: Icon(
            nowPlaying.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: nowPlaying.isBusy ? Colors.white38 : Colors.white,
          ),
          onPressed: nowPlaying.isBusy
              ? null
              : () async => notifier.togglePlayPause(),
        ),
      ],
    );
  }
}
