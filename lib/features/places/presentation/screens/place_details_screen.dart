import 'package:disfruta_antofagasta/features/places/presentation/widgets/full_screen_gallery.dart';
import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class PlaceDetailsScreen extends ConsumerStatefulWidget {
  final String placeId;

  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends ConsumerState<PlaceDetailsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _place;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadPlace);
  }

  Future<void> _loadPlace() async {
    setState(() {
      _loading = true;
      _error = null;
      _place = null;
    });

    try {
      final langCode = context.locale.languageCode;

      // ✅ Provider correcto en tu proyecto
      final dio = ref.read(dioProvider);

      debugPrint(
        '📍 [PlaceDetails] GET /get_punto id=${widget.placeId} lang=$langCode',
      );

      final resp = await dio.get(
        '/get_punto',
        queryParameters: {'post_id': widget.placeId, 'lang': langCode},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      if (!mounted) return;

      final data = resp.data;
      if (data is! Map) {
        setState(() {
          _error = tr('piece_detail.load_error');
          _loading = false;
        });
        return;
      }

      setState(() {
        _place = Map<String, dynamic>.from(data as Map);
        _loading = false;
      });
    } on DioException catch (e, st) {
      debugPrint('❌ [PlaceDetails] DioException: ${e.message}\n$st');
      if (!mounted) return;
      setState(() {
        _error = tr('piece_detail.load_error');
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('❌ [PlaceDetails] ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = tr('piece_detail.load_error');
        _loading = false;
      });
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  String _trOr(String key, String fallback) {
    final v = tr(key);
    return (v == key) ? fallback : v;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _place == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error ?? tr('piece_detail.not_found'),
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadPlace,
                    child: Text(
                      tr('common.retry', args: []).toString().isEmpty
                          ? 'Reintentar'
                          : tr('common.retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final place = _place!;
    final String titulo = (place['titulo'] ?? '') as String;
    final String tipo = (place['tipo'] ?? '') as String;

    final String heroImage =
        (place['imagen_high'] ?? place['imagen'] ?? '') as String;

    final String descHtml =
        (place['desc_larga_html'] ?? place['desc_larga'] ?? '') as String;

    final String? audioUrlRaw = (place['audio'] as String?)?.trim();
    final String? audioUrl = (audioUrlRaw == null || audioUrlRaw.isEmpty)
        ? null
        : audioUrlRaw;

    final List<String> gallery = ((place['img_medium'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .where(
          (url) =>
              url.isNotEmpty &&
              (url.startsWith('http://') || url.startsWith('https://')),
        )
        .toList();

    final audio = ref.watch(audioPlayerProvider);

    final playLabel = _trOr(
      'piece_detail.play_audio_button',
      'Reproducir audio',
    );
    final playingLabel = _trOr('piece_detail.playing_now', 'Reproduciendo');
    final pausedLabel = _trOr('piece_detail.paused', 'Pausado');
    final tapToPlayLabel = _trOr(
      'piece_detail.tap_to_play',
      'Tocar para reproducir',
    );

    // ✅ espacio para que el contenido no quede tapado por mini + bottom nav
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const navApprox = 56.0;
    const miniApprox = 74.0;
    const extra = 18.0;
    final bottomSpacer = bottomSafe + navApprox + miniApprox + extra;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: heroImage.isNotEmpty
                  ? Image.network(heroImage, fit: BoxFit.cover)
                  : Container(color: Colors.black12),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (tipo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                        color: Colors.white.withOpacity(0.06),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tipo,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ✅ REPRODUCTOR PRO (con progreso + tiempos, sin azul)
                  if (audioUrl != null) ...[
                    const SizedBox(height: 24),

                    StreamBuilder<PlayerState>(
                      stream: audio.playerStateStream,
                      builder: (context, snapshot) {
                        final nowPlaying = ref.watch(nowPlayingProvider);

                        final bool isThisActive =
                            (nowPlaying.url ?? '') == audioUrl;
                        final bool isThisPlaying =
                            isThisActive && audio.isPlaying;

                        final Duration duration = isThisActive
                            ? (audio.duration ?? Duration.zero)
                            : Duration.zero;

                        final Duration position = isThisActive
                            ? audio.position
                            : Duration.zero;

                        final notifier = ref.read(nowPlayingProvider.notifier);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: IconButton(
                                      iconSize: 26,
                                      icon: Icon(
                                        isThisPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                      ),
                                      onPressed: () async {
                                        final current = ref.read(
                                          nowPlayingProvider,
                                        );
                                        final activeNow =
                                            (current.url ?? '') == audioUrl;

                                        if (!activeNow) {
                                          await notifier.playFromUrl(
                                            url: audioUrl,
                                            title: titulo,
                                            subtitle: tipo,
                                            placeId: int.tryParse(
                                              widget.placeId,
                                            ),
                                            imageUrl: heroImage,
                                            descriptionHtml: descHtml,
                                          );
                                          return;
                                        }

                                        if (audio.isPlaying) {
                                          await notifier.pause();
                                        } else {
                                          await notifier.resume();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playLabel,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isThisActive
                                              ? (isThisPlaying
                                                    ? playingLabel
                                                    : pausedLabel)
                                              : tapToPlayLabel,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // ✅ Slider sin azul
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white24,
                                ),
                                child: Slider(
                                  value: duration.inMilliseconds == 0
                                      ? 0
                                      : position.inMilliseconds
                                            .clamp(0, duration.inMilliseconds)
                                            .toDouble(),
                                  min: 0,
                                  max: duration.inMilliseconds == 0
                                      ? 1
                                      : duration.inMilliseconds.toDouble(),
                                  onChanged: isThisActive
                                      ? (v) => audio.seek(
                                          Duration(milliseconds: v.round()),
                                        )
                                      : null,
                                ),
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _format(position),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _format(duration),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 28),
                  Text(
                    tr('piece_detail.description_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Html(data: descHtml),

                  const SizedBox(height: 28),

                  if (gallery.isNotEmpty) ...[
                    Text(
                      tr('piece_detail.images_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: gallery.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final img = gallery[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullScreenGallery(
                                    images: gallery,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Image.network(img, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ],

                  SizedBox(height: bottomSpacer),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
