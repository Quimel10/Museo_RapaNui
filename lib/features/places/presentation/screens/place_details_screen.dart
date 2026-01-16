import 'package:disfruta_antofagasta/features/places/presentation/state/place_provider.dart';
import 'package:disfruta_antofagasta/features/places/presentation/widgets/full_screen_gallery.dart';
import 'package:disfruta_antofagasta/features/places/presentation/widgets/section_error.dart';
import 'package:disfruta_antofagasta/shared/provider/api_client_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(placeProvider.notifier).placeDetails(widget.placeId);
    });

    _langSub = ref.listenManual<String>(languageProvider, (prev, next) async {
      await ref.read(placeProvider.notifier).placeDetails(widget.placeId);
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

  Future<void> _hardRetry() async {
    // ✅ recrea Dio/HttpClient (equivalente a cerrar y abrir)
    ref.invalidate(dioProvider);
    ref.invalidate(apiClientProvider);

    await Future.delayed(const Duration(milliseconds: 120));
    await ref.read(placeProvider.notifier).placeDetails(widget.placeId);
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

  String _canonicalKey(String url) {
    var u = url.trim();
    if (u.isEmpty) return '';

    final q = u.indexOf('?');
    if (q != -1) u = u.substring(0, q);

    u = u.replaceFirst(RegExp(r'^https?:\/\/', caseSensitive: false), '');
    u = u.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');

    var lower = u.toLowerCase();

    lower = lower.replaceAllMapped(
      RegExp(
        r'-\d{2,5}x\d{2,5}(?=\.(jpg|jpeg|png|webp)$)',
        caseSensitive: false,
      ),
      (m) => '',
    );

    lower = lower.replaceAllMapped(
      RegExp(r'-scaled(?=\.(jpg|jpeg|png|webp)$)', caseSensitive: false),
      (m) => '',
    );

    lower = lower.replaceAllMapped(
      RegExp(r'-\d+(?=\.(jpg|jpeg|png|webp)$)', caseSensitive: false),
      (m) => '',
    );

    return lower;
  }

  int _qualityScore(String url) {
    final u = url.toLowerCase();

    int score = 1000;

    if (u.contains('thumb') || u.contains('thumbnail')) score -= 400;

    if (RegExp(r'-\d{2,5}x\d{2,5}\.(jpg|jpeg|png|webp)$').hasMatch(u)) {
      score -= 250;
    }

    if (u.contains('-scaled.')) score -= 80;

    if (u.contains('full') || u.contains('large') || u.contains('original')) {
      score += 60;
    }

    return score;
  }

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

    // ✅ AQUÍ está la regla final
    final bool loadedOk = placeState.placeDetailsLoadedOk == true;

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Si NO cargó OK (offline / servidor) mostramos SIEMPRE el mensaje.
    if (!loadedOk) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SectionError(
              title: 'Sin conexión',
              message:
                  error ??
                  'No pudimos cargar esta pieza.\nRevisa tu señal o Wi-Fi e inténtalo nuevamente.',
              buttonText: _trOr('common.retry', 'Reintentar'),
              icon: Icons.wifi_off_rounded,
              onRetry: _hardRetry,
            ),
          ),
        ),
      );
    }

    // Si llegamos aquí, la última carga fue OK. Por seguridad:
    if (place == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Text(
              _trOr('piece_detail.not_found', 'No encontramos esta pieza.'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onBackground,
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
