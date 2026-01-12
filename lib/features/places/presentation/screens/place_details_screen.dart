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

  // ---------------------------------------------------------------------------
  // ✅ Extraer imágenes embebidas en HTML (fallback)
  // ---------------------------------------------------------------------------
  List<String> _extractImgUrlsFromHtml(String html) {
    if (html.trim().isEmpty) return [];

    final reg = RegExp(
      r'(?:src|data-src)\s*=\s*"([^"]+)"',
      caseSensitive: false,
    );
    final matches = reg.allMatches(html);

    final out = <String>[];
    for (final m in matches) {
      final url = (m.group(1) ?? '').trim();
      if (url.isEmpty) continue;
      if (url.startsWith('data:')) continue;
      out.add(url);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // ✅ Canonical key más agresivo para dedup:
  // - quita query (?ver=)
  // - normaliza http/https + www
  // - quita sufijo -300x300
  // - quita -scaled
  // - quita -1 / -2 (duplicados WP)
  // ---------------------------------------------------------------------------
  String _canonicalKey(String url) {
    var u = url.trim();
    if (u.isEmpty) return '';

    // quita query
    final q = u.indexOf('?');
    if (q != -1) u = u.substring(0, q);

    // normaliza protocolo + www
    u = u.replaceFirst(RegExp(r'^https?:\/\/', caseSensitive: false), '');
    u = u.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');

    var lower = u.toLowerCase();

    // quita -WIDTHxHEIGHT antes de extensión
    lower = lower.replaceAllMapped(
      RegExp(
        r'-\d{2,5}x\d{2,5}(?=\.(jpg|jpeg|png|webp)$)',
        caseSensitive: false,
      ),
      (m) => '',
    );

    // quita -scaled antes de extensión
    lower = lower.replaceAllMapped(
      RegExp(r'-scaled(?=\.(jpg|jpeg|png|webp)$)', caseSensitive: false),
      (m) => '',
    );

    // quita sufijo -1 / -2 / -3 antes de extensión (WP dup)
    lower = lower.replaceAllMapped(
      RegExp(r'-\d+(?=\.(jpg|jpeg|png|webp)$)', caseSensitive: false),
      (m) => '',
    );

    return lower;
  }

  // ---------------------------------------------------------------------------
  // ✅ Score de "calidad" para elegir la mejor URL cuando hay duplicados
  // Más alto = mejor.
  // ---------------------------------------------------------------------------
  int _qualityScore(String url) {
    final u = url.toLowerCase();

    int score = 1000;

    // penaliza thumbnails
    if (u.contains('thumb') || u.contains('thumbnail')) score -= 400;

    // penaliza sizes típicos
    if (RegExp(r'-\d{2,5}x\d{2,5}\.(jpg|jpeg|png|webp)$').hasMatch(u)) {
      score -= 250;
    }

    // penaliza scaled (a veces WP lo usa como "derivado")
    if (u.contains('-scaled.')) score -= 80;

    // bonus si parece "full" / "large" / "original"
    if (u.contains('full') || u.contains('large') || u.contains('original')) {
      score += 60;
    }

    return score;
  }

  // ---------------------------------------------------------------------------
  // ✅ Build galería final:
  // - Usa SOLO 1 hero (el mejor disponible)
  // - Dedup por canonicalKey
  // - Si choca, reemplaza por mejor calidad
  // Orden de preferencia de fuentes:
  // 1) hero (best)
  // 2) imgMedium
  // 3) imgThumb
  // 4) <img> del HTML
  // ---------------------------------------------------------------------------
  List<String> _buildGallery({
    required String heroHigh,
    required String hero,
    required List<String> imgMedium,
    required List<String> imgThumb,
    required String html,
  }) {
    final heroBest = heroHigh.trim().isNotEmpty ? heroHigh.trim() : hero.trim();

    final candidates = <String>[
      if (heroBest.isNotEmpty) heroBest,
      ...imgMedium.map((e) => e.trim()),
      ...imgThumb.map((e) => e.trim()),
      ..._extractImgUrlsFromHtml(html).map((e) => e.trim()),
    ].where((e) => e.isNotEmpty).toList();

    // Mantenemos orden, pero guardamos el "mejor" por key.
    final keysInOrder = <String>[];
    final bestUrlByKey = <String, String>{};
    final bestScoreByKey = <String, int>{};

    for (final url in candidates) {
      final key = _canonicalKey(url);
      if (key.isEmpty) continue;

      final score = _qualityScore(url);

      if (!bestUrlByKey.containsKey(key)) {
        bestUrlByKey[key] = url;
        bestScoreByKey[key] = score;
        keysInOrder.add(key);
      } else {
        final currentScore = bestScoreByKey[key] ?? -999999;
        if (score > currentScore) {
          bestUrlByKey[key] = url;
          bestScoreByKey[key] = score;
        }
      }
    }

    final out = <String>[];
    for (final k in keysInOrder) {
      final u = bestUrlByKey[k];
      if (u != null && u.trim().isNotEmpty) out.add(u.trim());
    }

    return out;
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

    final String heroHigh = p.imagenHigh.toString();
    final String hero = p.imagen.toString();

    final String heroImage = (heroHigh.trim().isNotEmpty)
        ? heroHigh.trim()
        : hero.trim();

    final String descHtml =
        (p.descLargaHtml?.toString().trim().isNotEmpty == true)
        ? p.descLargaHtml!.toString()
        : p.descLarga.toString();

    final String? audioUrl = (p.audio.toString().trim().isNotEmpty)
        ? p.audio.toString().trim()
        : null;

    final galleryUrls = _buildGallery(
      heroHigh: heroHigh,
      hero: hero,
      imgMedium: p.imgMedium,
      imgThumb: p.imgThumb,
      html: descHtml,
    );

    // ignore: avoid_print
    print(
      "🖼️ GALLERY FINAL => ${galleryUrls.length} | "
      "hero: ${heroImage.isNotEmpty ? heroImage : '(none)'} | "
      "first: ${galleryUrls.isNotEmpty ? galleryUrls.first : '(none)'}",
    );

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
                  ? GestureDetector(
                      onTap: galleryUrls.isEmpty
                          ? null
                          : () => _openGallery(context, galleryUrls, 0),
                      child: Image.network(
                        heroImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: cs.surfaceVariant),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: cs.surfaceVariant,
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                          );
                        },
                      ),
                    )
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
                                                images: galleryUrls,
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
                    SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: galleryUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final url = galleryUrls[i];

                          // ✅ Tag estable, evita problemas cuando URL cambia / dup
                          final heroTag = 'gallery_${p.id}_$i';

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
