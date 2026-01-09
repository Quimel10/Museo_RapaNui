// lib/features/places/presentation/screens/place_details_screen.dart

import 'package:disfruta_antofagasta/features/places/presentation/state/place_provider.dart';
import 'package:disfruta_antofagasta/features/places/presentation/widgets/full_screen_gallery.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlaceDetailsScreen extends ConsumerStatefulWidget {
  final String placeId;

  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  ConsumerState<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends ConsumerState<PlaceDetailsScreen> {
  ProviderSubscription<String>? _langSub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(placeProvider.notifier).placeDetails(widget.placeId);
    });

    _langSub = ref.listenManual<String>(languageProvider, (prev, next) {
      ref.read(placeProvider.notifier).placeDetails(widget.placeId);
    });
  }

  @override
  void dispose() {
    _langSub?.close();
    super.dispose();
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

  void _openGallery(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    if (images.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FullScreenGallery(images: images, initialIndex: initialIndex),
      ),
    );
  }

  // ===========================================================================
  // ✅ SOLO GALERÍA DEL "PUNTO TURÍSTICO"
  // ===========================================================================
  List<String> _extractTouristPointGallery(PlaceEntity p) {
    final out = <String>[];

    List<String> normalizeList(dynamic v) {
      if (v is List) {
        return v
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const <String>[];
    }

    Map<String, dynamic>? asMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    try {
      final dynamic any = p;

      final candidates = <dynamic>[
        any.infoPuntoTuristico,
        any.infoPuntoTuristicoData,
        any.puntoTuristico,
        any.punto_turistico,
        any.touristPoint,
        any.tourist_point,
      ];

      for (final node in candidates) {
        final m = asMap(node);
        if (m == null) continue;

        final keys = [
          'galeriaFotos',
          'galeria_fotos',
          'galeria',
          'gallery',
          'fotos',
          'images',
          'imagenes',
        ];

        for (final k in keys) {
          if (m.containsKey(k)) {
            final list = normalizeList(m[k]);
            if (list.isNotEmpty) {
              out.addAll(list);
              break;
            }
          }
        }

        if (out.isNotEmpty) break;
      }
    } catch (_) {}

    // fallback (por si tu endpoint viejo solo manda imgMedium)
    if (out.isEmpty) {
      try {
        final dynamic any = p;
        final dynamic med = any.imgMedium;
        final list = normalizeList(med);
        if (list.isNotEmpty) out.addAll(list);
      } catch (_) {}
    }

    final seen = <String>{};
    final dedup = <String>[];
    for (final u in out) {
      if (seen.add(u)) dedup.add(u);
    }
    return dedup;
  }

  @override
  Widget build(BuildContext context) {
    final placeState = ref.watch(placeProvider);
    final audio = ref.watch(audioPlayerProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bool isLoading = placeState.isLoadingPlaceDetails == true;
    final String? error = placeState.errorMessage;
    final PlaceEntity? place = placeState.placeDetails;

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (place == null || error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error ?? tr('piece_detail.not_found'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref
                        .read(placeProvider.notifier)
                        .placeDetails(widget.placeId),
                    child: Text(
                      tr('common.retry') == 'common.retry'
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

    final p = place;

    final String titulo = p.titulo.toString();
    final String tipo = p.tipo.toString();

    final String heroImage =
        (p.imagenHigh?.toString().trim().isNotEmpty == true)
        ? p.imagenHigh!.toString()
        : (p.imagen?.toString() ?? '');

    final String descHtml =
        (p.descLargaHtml?.toString().trim().isNotEmpty == true)
        ? p.descLargaHtml!.toString()
        : (p.descLarga?.toString() ?? '');

    final String? audioUrl = (p.audio?.toString().trim().isNotEmpty == true)
        ? p.audio!.toString().trim()
        : null;

    final galleryUrls = _extractTouristPointGallery(p);

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

    final cardBg = cs.surface;
    final cardBorder = cs.outline.withOpacity(0.6);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: cs.onBackground),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: heroImage.isNotEmpty
                  ? Image.network(heroImage, fit: BoxFit.cover)
                  : Container(color: cs.surfaceVariant),
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: cs.onBackground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (audioUrl != null) ...[
                    const SizedBox(height: 24),
                    StreamBuilder<PositionData>(
                      stream: audio.positionDataStream,
                      builder: (context, snapshot) {
                        final data =
                            snapshot.data ??
                            const PositionData(
                              Duration.zero,
                              Duration.zero,
                              Duration.zero,
                            );

                        final nowPlaying = ref.watch(nowPlayingProvider);
                        final notifier = ref.read(nowPlayingProvider.notifier);

                        final bool isThisActive =
                            (nowPlaying.url ?? '') == audioUrl;
                        final bool isThisPlaying =
                            isThisActive && nowPlaying.isPlaying;

                        final duration = isThisActive
                            ? data.duration
                            : Duration.zero;
                        final position = isThisActive
                            ? data.position
                            : Duration.zero;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    iconSize: 30,
                                    icon: Icon(
                                      isThisPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                    onPressed: nowPlaying.isBusy
                                        ? null
                                        : () async {
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
                                                placeId: p.id,
                                                place: p,
                                                imageUrl: heroImage,
                                                descriptionHtml: descHtml,
                                              );
                                            } else {
                                              await notifier.toggle();
                                            }
                                          },
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playLabel,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        Text(
                                          isThisActive
                                              ? (isThisPlaying
                                                    ? playingLabel
                                                    : pausedLabel)
                                              : tapToPlayLabel,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: duration.inMilliseconds == 0
                                    ? 0
                                    : position.inMilliseconds
                                          .clamp(0, duration.inMilliseconds)
                                          .toDouble(),
                                min: 0,
                                max: duration.inMilliseconds == 0
                                    ? 1
                                    : duration.inMilliseconds.toDouble(),
                                onChanged: (!isThisActive || nowPlaying.isBusy)
                                    ? null
                                    : (v) => audio.seek(
                                        Duration(milliseconds: v.round()),
                                      ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_format(position)),
                                  Text(_format(duration)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 28),
                  Html(data: descHtml),

                  // =======================
                  // ✅ GALERÍA (con HERO)
                  // =======================
                  if (galleryUrls.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text(
                      _trOr('piece_detail.photos', 'Fotos'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onBackground,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // un poquito más grande, se ve “pro”
                    SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: galleryUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final url = galleryUrls[i];
                          final heroTag = 'gallery_$url';

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _openGallery(context, galleryUrls, i),
                            child: Container(
                              width: 210,
                              decoration: BoxDecoration(
                                color: cs.surfaceVariant,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: cs.outline.withOpacity(0.35),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // ✅ HERO hacia fullscreen
                                    Hero(
                                      tag: heroTag,
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: cs.onSurfaceVariant
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                value:
                                                    progress.expectedTotalBytes ==
                                                        null
                                                    ? null
                                                    : progress.cumulativeBytesLoaded /
                                                          (progress
                                                                  .expectedTotalBytes ??
                                                              1),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    Positioned(
                                      right: 10,
                                      bottom: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.45),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.open_in_full_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
