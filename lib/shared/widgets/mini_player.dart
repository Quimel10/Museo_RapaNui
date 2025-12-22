import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);

    if (!nowPlaying.hasAudio) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const _FullPlayerSheet(),
        );
      },
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.museum, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  nowPlaying.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              IconButton(
                icon: Icon(
                  nowPlaying.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await ref.read(nowPlayingProvider.notifier).toggle();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullPlayerSheet extends ConsumerWidget {
  const _FullPlayerSheet();

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    final audio = ref.watch(audioPlayerProvider);

    final duration = audio.duration ?? const Duration(seconds: 0);
    final position = audio.position;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.40,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1B1B1B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 25),

              Text(
                nowPlaying.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  decoration: TextDecoration.none,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                nowPlaying.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),

              const SizedBox(height: 30),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                ),
                child: Slider(
                  value: position.inMilliseconds
                      .clamp(0, duration.inMilliseconds)
                      .toDouble(),
                  min: 0,
                  max: duration.inMilliseconds.toDouble() == 0
                      ? 1
                      : duration.inMilliseconds.toDouble(),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: (v) {
                    final target = Duration(milliseconds: v.round());
                    audio.seek(target);
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _format(position),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    _format(duration),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              IconButton(
                iconSize: 70,
                icon: Icon(
                  nowPlaying.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await ref.read(nowPlayingProvider.notifier).toggle();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
