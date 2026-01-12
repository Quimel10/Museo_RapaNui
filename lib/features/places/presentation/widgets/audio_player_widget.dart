// lib/features/places/presentation/widgets/audio_player_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';

class AudioPlayerWidget extends ConsumerWidget {
  final String audioUrl;
  final String title;
  final PlaceEntity? place;
  final String subtitle;
  final String? imageUrl;
  final String? descriptionHtml;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.title,
    this.place,
    this.subtitle = '',
    this.imageUrl,
    this.descriptionHtml,
  });

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    final audio = ref.watch(audioPlayerProvider);
    final notifier = ref.read(nowPlayingProvider.notifier);

    final url = audioUrl.trim();
    if (url.isEmpty) {
      return Text(
        tr('player.audio_error'),
        style: const TextStyle(color: Colors.white70),
      );
    }

    final bool isActive = (nowPlaying.url ?? '') == url;
    final bool isPlaying = isActive && nowPlaying.isPlaying;
    final bool disabled = nowPlaying.isBusy;

    Future<void> onTap() async {
      if (disabled) return;

      if (place != null) {
        // ✅ Caso ideal: con PlaceEntity completo
        await notifier.toggleFor(place!);
        return;
      }

      // ✅ Fallback: NO inventamos PlaceEntity (porque tu PlaceEntity exige muchos campos)
      // En su lugar usamos playFromUrl, que ya acepta title/subtitle/image/description.
      if (!isActive) {
        await notifier.playFromUrl(
          url: url,
          title: title,
          subtitle: subtitle,
          place: null,
          placeId: null,
          imageUrl: imageUrl,
          descriptionHtml: descriptionHtml,
          images: const [], // si tienes una lista, pásala aquí
        );
      } else {
        await notifier.togglePlayPause();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: disabled ? null : onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: disabled ? 0.5 : 1,
                child: Container(
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
              ),
              const SizedBox(width: 12),
              Text(
                isPlaying ? tr('player.pause_audio') : tr('player.play_audio'),
                style: TextStyle(
                  color: disabled ? Colors.white54 : Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<Duration>(
          stream: audio.positionStream,
          initialData: audio.position,
          builder: (_, snap) {
            final pos = isActive ? (snap.data ?? Duration.zero) : Duration.zero;
            final dur = isActive
                ? (audio.duration ?? Duration.zero)
                : Duration.zero;

            final maxMs = dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds;

            return Column(
              children: [
                Slider(
                  value: pos.inMilliseconds.clamp(0, maxMs).toDouble(),
                  max: maxMs.toDouble(),
                  onChanged: disabled
                      ? null
                      : (v) => audio.seek(Duration(milliseconds: v.toInt())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(pos),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    Text(
                      _format(dur),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
