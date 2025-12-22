import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';

class AudioPlayerWidget extends ConsumerWidget {
  final String audioUrl;
  final String title;

  /// Opcional: si tenés la pieza completa, mejor (para que el mini-player tenga imagen, id, etc.)
  final PlaceEntity? place;

  /// Opcional: subtítulo
  final String subtitle;

  /// ✅ NUEVO: portada y descripción (cuando NO tenemos PlaceEntity)
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
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    final audio = ref.watch(audioPlayerProvider);

    final url = audioUrl.trim();

    if (url.isEmpty) {
      return Text(
        tr('player.audio_error'),
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      );
    }

    final bool isThisTrackActive = (nowPlaying.url ?? '') == url;

    // ✅ CLAVE: el estado visual NO viene de audio.isPlaying, viene del estado global sincronizado
    final bool isPlayingThis = isThisTrackActive && nowPlaying.isPlaying;

    Future<void> onToggle() async {
      final notifier = ref.read(nowPlayingProvider.notifier);

      // Si no es el track actual, lo cargamos y reproducimos
      if (!isThisTrackActive) {
        await notifier.playFromUrl(
          url: url,
          title: title,
          subtitle: subtitle.isNotEmpty ? subtitle : (place?.descCorta ?? ''),
          placeId: place?.id,
          place: place,
          imageUrl: imageUrl,
          descriptionHtml: descriptionHtml,
        );
        return;
      }

      // ✅ Si es el track actual: SIEMPRE toggle (misma lógica que mini-player)
      await notifier.toggle();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onToggle,
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
                  isPlayingThis ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isPlayingThis
                    ? tr('player.pause_audio')
                    : tr('player.play_audio'),
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

        StreamBuilder<Duration>(
          stream: audio.positionStream,
          initialData: audio.position,
          builder: (context, snapPos) {
            final pos = isThisTrackActive
                ? (snapPos.data ?? Duration.zero)
                : Duration.zero;

            final dur = isThisTrackActive
                ? (audio.duration ?? Duration.zero)
                : Duration.zero;

            final totalMs = dur.inMilliseconds.clamp(1, 24 * 60 * 60 * 1000);
            final posMs = pos.inMilliseconds.clamp(0, totalMs);

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: totalMs.toDouble(),
                    value: posMs.toDouble(),
                    onChanged: (v) async {
                      final newPos = Duration(milliseconds: v.toInt());
                      final notifier = ref.read(nowPlayingProvider.notifier);

                      // Si no está activo, primero lo activamos y luego seek
                      if (!isThisTrackActive) {
                        await notifier.playFromUrl(
                          url: url,
                          title: title,
                          subtitle: subtitle.isNotEmpty
                              ? subtitle
                              : (place?.descCorta ?? ''),
                          placeId: place?.id,
                          place: place,
                          imageUrl: imageUrl,
                          descriptionHtml: descriptionHtml,
                        );
                        await audio.seek(newPos);
                      } else {
                        await audio.seek(newPos);
                      }
                    },
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _format(pos),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _format(dur),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
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
