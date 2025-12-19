// lib/shared/audio/now_playing_player.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// ✅ Solo este import (NO style.dart, porque tu flutter_html no lo trae)
import 'package:flutter_html/flutter_html.dart';

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

    // ✅ Cover: primero PlaceEntity (Home), si no existe usa nowPlaying.imageUrl (Piezas)
    final String cover = (place != null && place.imagenHigh.isNotEmpty)
        ? place.imagenHigh
        : (nowPlaying.imageUrl ?? '');

    return SafeArea(
      // margen para no pisar el bottom nav / gestos
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
                    child: cover.isNotEmpty
                        ? Image.network(
                            cover,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _miniPlaceholder(),
                          )
                        : _miniPlaceholder(),
                  ),
                ),
                const SizedBox(width: 10),

                // Título SIN subrayado
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

                // Botón play/pausa usando provider
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
                        final notifier = ref.read(nowPlayingProvider.notifier);
                        if (isPlaying) {
                          await notifier.pause();
                        } else {
                          await notifier.resume();
                        }
                      },
                    );
                  },
                ),

                // ❌ Botón cerrar (X)
                IconButton(
                  iconSize: 22,
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () async {
                    await ref.read(nowPlayingProvider.notifier).clear();
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
      backgroundColor: Colors.transparent,
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

/// FULL SCREEN PLAYER – con animación y botón X para cerrar
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

    // ✅ Cover: primero PlaceEntity, si no existe usa nowPlaying.imageUrl
    final String cover = (place != null && place.imagenHigh.isNotEmpty)
        ? place.imagenHigh
        : (nowPlaying.imageUrl ?? '');

    // ✅ Descripción HTML (si viene)
    final String descHtml = (nowPlaying.descriptionHtml ?? '').trim();

    // ✅ Esto es lo que arregla tu problema: padding real de status bar + margen extra
    final double topInset = MediaQuery.of(context).padding.top;

    return SafeArea(
      // 👇 IMPORTANTÍSIMO: no uses el top de SafeArea, lo controlamos nosotros
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de arrastre + botón X (más abajo, sin chocar con la hora)
            Padding(
              padding: EdgeInsets.only(
                top: topInset + 34, // ✅ baja la X y el header
                left: 8,
                right: 8,
                bottom: 6,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40),
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
                    onPressed: () => Navigator.of(context).pop(),
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
                          child: cover.isNotEmpty
                              ? Image.network(
                                  cover,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _fullPlaceholder(),
                                )
                              : _fullPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                              final notifier = ref.read(
                                nowPlayingProvider.notifier,
                              );

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
                                    if (isPlaying) {
                                      await notifier.pause();
                                    } else {
                                      await notifier.resume();
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
                              final clamped = (d > Duration.zero && target > d)
                                  ? d
                                  : target;
                              audio.seek(clamped);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Botón cerrar reproducción (stop + limpiar estado)
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          await ref.read(nowPlayingProvider.notifier).clear();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.stop_rounded,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          'Detener audio',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),

                    // ✅ Descripción completa (si vino desde Piezas)
                    if (descHtml.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Descripción',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Html(data: descHtml),
                    ],

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
