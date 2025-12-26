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
import 'package:just_audio/just_audio.dart';

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

  @override
  Widget build(BuildContext context) {
    final placeState = ref.watch(placeProvider);

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

    final String imagenHigh = p.imagenHigh.toString();
    final String imagen = p.imagen.toString();
    final String heroImage = (imagenHigh.trim().isNotEmpty)
        ? imagenHigh.trim()
        : imagen.trim();

    final String descHtml =
        (p.descLargaHtml?.toString().trim().isNotEmpty == true)
        ? p.descLargaHtml!.toString()
        : (p.descLarga?.toString() ?? '');

    final String? audioUrl = (p.audio?.toString().trim().isNotEmpty == true)
        ? p.audio!.toString().trim()
        : null;

    final List<String> gallery =
        ((p.imgMedium as dynamic) is List
                ? List<dynamic>.from(p.imgMedium as dynamic)
                : const <dynamic>[])
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

    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const navApprox = 56.0;
    const miniApprox = 74.0;
    const extra = 18.0;
    final bottomSpacer = bottomSafe + navApprox + miniApprox + extra;

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
                  const SizedBox(height: 12),

                  if (tipo.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                        color: cs.surfaceVariant,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tipo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (audioUrl != null) ...[
                    const SizedBox(height: 24),
                    StreamBuilder<PlayerState>(
                      stream: audio.playerStateStream,
                      builder: (context, snapshot) {
                        final nowPlaying = ref.watch(nowPlayingProvider);
                        final notifier = ref.read(nowPlayingProvider.notifier);

                        final bool isThisActive =
                            (nowPlaying.url ?? '') == audioUrl;
                        final bool isThisPlaying =
                            isThisActive && nowPlaying.isPlaying;

                        final Duration duration = isThisActive
                            ? (audio.duration ?? Duration.zero)
                            : Duration.zero;

                        final Duration position = isThisActive
                            ? audio.position
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
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: cs.surfaceVariant,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: cardBorder),
                                    ),
                                    child: IconButton(
                                      iconSize: 26,
                                      icon: Icon(
                                        isThisPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: cs.onSurface,
                                      ),
                                      onPressed: nowPlaying.isBusy
                                          ? null
                                          : () async {
                                              final current = ref.read(
                                                nowPlayingProvider,
                                              );
                                              final activeNow =
                                                  (current.url ?? '') ==
                                                  audioUrl;

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
                                                return;
                                              }

                                              await notifier.toggle();
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
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: cs.onSurface,
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
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                  activeTrackColor: cs.onSurface,
                                  inactiveTrackColor: cs.onSurface.withOpacity(
                                    0.25,
                                  ),
                                  thumbColor: cs.onSurface,
                                  overlayColor: cs.onSurface.withOpacity(0.12),
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
                                  onChanged:
                                      (!isThisActive || nowPlaying.isBusy)
                                      ? null
                                      : (v) => audio.seek(
                                          Duration(milliseconds: v.round()),
                                        ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _format(position),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _format(duration),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: cs.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ FIX: estilos sin style.dart (compat con flutter_html 3.0.0)
                  Html(
                    data: descHtml,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: cs.onBackground,
                        fontSize: FontSize(16),
                        lineHeight: LineHeight.number(1.55),
                      ),
                      "p": Style(
                        color: cs.onBackground,
                        fontSize: FontSize(16),
                        lineHeight: LineHeight.number(1.55),
                      ),
                      "li": Style(
                        color: cs.onBackground,
                        fontSize: FontSize(16),
                        lineHeight: LineHeight.number(1.55),
                      ),
                      "strong": Style(color: cs.onBackground),
                      "em": Style(color: cs.onBackground),
                      "a": Style(
                        color: cs.primary,
                        textDecoration: TextDecoration.underline,
                      ),
                    },
                  ),

                  const SizedBox(height: 28),

                  if (gallery.isNotEmpty) ...[
                    Text(
                      tr('piece_detail.images_title'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: cs.onBackground,
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
