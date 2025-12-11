import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';

/// MINI PLAYER (barra de abajo) – estilo Louvre, SIN corazón ni subrayado
class NowPlayingMiniBar extends ConsumerWidget {
  const NowPlayingMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);

    // Nada cargado → no mostrar mini-player
    if (!nowPlaying.hasAudio) {
      return const SizedBox.shrink();
    }

    final PlaceEntity? place = nowPlaying.place;
    final audio = ref.watch(audioPlayerProvider);

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 56),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () => _openFullPlayer(context),
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! < -6) {
              _openFullPlayer(context);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF101010),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Mini portada
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: place != null && place.imagenHigh.isNotEmpty
                        ? Image.network(
                            place.imagenHigh,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _miniPlaceholder(),
                          )
                        : _miniPlaceholder(),
                  ),
                ),
                const SizedBox(width: 10),

                // Título SIN SUBRAYADO
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

                const SizedBox(width: 8),

                // Botón play/pausa
                StreamBuilder<PlayerState>(
                  stream: audio.playerStateStream,
                  builder: (context, snapshot) {
                    final isPlaying = audio.isPlaying;
                    return IconButton(
                      iconSize: 26,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final url = nowPlaying.url;
                        if (url == null || url.isEmpty) return;

                        if (isPlaying) {
                          await audio.pause();
                          ref
                              .read(nowPlayingProvider.notifier)
                              .setIsPlaying(false);
                        } else {
                          await audio.playOrResume(url);
                          ref
                              .read(nowPlayingProvider.notifier)
                              .setIsPlaying(true);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      color: Colors.white10,
      child: const Icon(Icons.museum_rounded, color: Colors.white, size: 20),
    );
  }

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // para que se vea la animación
      barrierColor: Colors.black54,
      builder: (_) {
        // ✨ Animación fade + slide up
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - value)),
                child: child,
              ),
            );
          },
          child: const NowPlayingFullPlayerSheet(),
        );
      },
    );
  }
}

/// FULL SCREEN PLAYER – como en la app modelo,
/// con animación y botón X para cerrar
class NowPlayingFullPlayerSheet extends ConsumerWidget {
  const NowPlayingFullPlayerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider);

    if (!nowPlaying.hasAudio) {
      return const SizedBox.shrink();
    }

    final PlaceEntity? place = nowPlaying.place;
    final audio = ref.watch(audioPlayerProvider);
    final duration = audio.duration ?? const Duration(seconds: 0);

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de arrastre + botón X
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
              child: Row(
                children: [
                  const SizedBox(width: 40), // espacio izq para que centre bien
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => Navigator.of(context).pop(), // ❌ cerrar
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen grande
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: place != null && place.imagenHigh.isNotEmpty
                              ? Image.network(
                                  place.imagenHigh,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _fullPlaceholder(),
                                )
                              : _fullPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título grande sin subrayado
                    Text(
                      nowPlaying.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Descripción corta sin subrayado
                    if (nowPlaying.subtitle.isNotEmpty)
                      Text(
                        nowPlaying.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                          decoration: TextDecoration.none,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // PROGRESS BAR + tiempos
                    StreamBuilder<Duration>(
                      stream: audio.positionStream,
                      initialData: audio.position,
                      builder: (context, snapshot) {
                        final pos = snapshot.data ?? Duration.zero;

                        final effectiveDuration = duration.inMilliseconds > 0
                            ? duration
                            : pos;

                        final maxMs = effectiveDuration.inMilliseconds > 0
                            ? effectiveDuration.inMilliseconds
                            : 1;

                        final sliderMax = maxMs.toDouble();
                        final valueMs = pos.inMilliseconds.clamp(0, maxMs);
                        final sliderValue = valueMs.toDouble();

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7,
                                ),
                              ),
                              child: Slider(
                                value: sliderValue,
                                max: sliderMax,
                                onChanged: (v) {
                                  final target = Duration(
                                    milliseconds: v.round(),
                                  );
                                  audio.seek(target);
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(pos),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(effectiveDuration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // CONTROLES (con saltos ±10s)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 30,
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // aquí podrías luego ir a la pieza anterior
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            iconSize: 30,
                            icon: const Icon(
                              Icons.replay_10_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              final current = audio.position;
                              final target =
                                  current - const Duration(seconds: 10);
                              audio.seek(
                                target < Duration.zero ? Duration.zero : target,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          StreamBuilder<PlayerState>(
                            stream: audio.playerStateStream,
                            builder: (context, snapshot) {
                              final isPlaying = audio.isPlaying;
                              final url = nowPlaying.url ?? '';

                              return Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  iconSize: 38,
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.black,
                                  ),
                                  onPressed: () async {
                                    if (url.isEmpty) return;
                                    if (isPlaying) {
                                      await audio.pause();
                                      ref
                                          .read(nowPlayingProvider.notifier)
                                          .setIsPlaying(false);
                                    } else {
                                      await audio.playOrResume(url);
                                      ref
                                          .read(nowPlayingProvider.notifier)
                                          .setIsPlaying(true);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            iconSize: 30,
                            icon: const Icon(
                              Icons.forward_10_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              final current = audio.position;
                              final d = audio.duration ?? Duration.zero;
                              final target =
                                  current + const Duration(seconds: 10);
                              final clamped = target > d && d > Duration.zero
                                  ? d
                                  : target;
                              audio.seek(clamped);
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            iconSize: 30,
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // aquí podrías luego ir a la siguiente pieza
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullPlaceholder() {
    return Container(
      color: Colors.white10,
      child: const Center(
        child: Icon(Icons.museum_rounded, color: Colors.white, size: 48),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
