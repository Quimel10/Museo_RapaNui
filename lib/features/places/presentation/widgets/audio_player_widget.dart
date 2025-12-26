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
        // 🔥 CASO IDEAL
        await notifier.toggleFor(place!);
      } else {
        // fallback sin PlaceEntity
        if (!isActive) {
          await notifier.playFromPlace(
            _FakePlace(
              id: null,
              titulo: title,
              descCorta: subtitle,
              audio: url,
              imagen: imageUrl,
              descripcionHtml: descriptionHtml,
            ),
          );
        } else {
          await notifier.togglePlayPause();
        }
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
            final pos = isActive ? snap.data ?? Duration.zero : Duration.zero;
            final dur = isActive
                ? audio.duration ?? Duration.zero
                : Duration.zero;

            return Column(
              children: [
                Slider(
                  value: pos.inMilliseconds
                      .clamp(
                        0,
                        dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds,
                      )
                      .toDouble(),
                  max: dur.inMilliseconds == 0
                      ? 1
                      : dur.inMilliseconds.toDouble(),
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

/// 🔧 fallback interno SOLO para cuando no hay PlaceEntity
class _FakePlace implements PlaceEntity {
  @override
  final int? id;
  final String titulo;
  final String descCorta;
  final String audio;
  final String? imagen;
  final String? descripcionHtml;

  _FakePlace({
    required this.id,
    required this.titulo,
    required this.descCorta,
    required this.audio,
    this.imagen,
    this.descripcionHtml,
  });
}
