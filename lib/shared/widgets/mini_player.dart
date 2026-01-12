// lib/shared/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';
import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  final PageController _miniCoverCtrl = PageController();
  int _miniPage = 0;
  double _dragDy = 0;

  // cache para no pedir get_punto en loop
  String? _cacheKey;
  Future<List<String>>? _imagesFuture;

  @override
  void dispose() {
    _miniCoverCtrl.dispose();
    super.dispose();
  }

  // ============================
  //  PARSER ROBUSTO DE URLS
  // ============================
  List<String> _parseUrls(dynamic raw) {
    final out = <String>[];

    void addUrl(String? u) {
      final s = (u ?? '').trim();
      if (s.isEmpty) return;
      if (!(s.startsWith('http://') || s.startsWith('https://'))) return;
      out.add(s);
    }

    if (raw == null) return out;

    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          addUrl(item);
        } else if (item is Map) {
          addUrl(item['url']?.toString());
          addUrl(item['src']?.toString());
          addUrl(item['image']?.toString());
          addUrl(item['guid']?.toString());
          addUrl(item['link']?.toString());
        } else {
          addUrl(item?.toString());
        }
      }
      return out;
    }

    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return out;

      if (s.startsWith('http://') || s.startsWith('https://')) {
        addUrl(s);
        return out;
      }

      final parts = s.contains('|') ? s.split('|') : s.split(',');
      for (final p in parts) {
        addUrl(p);
      }
      return out;
    }

    if (raw is Map) {
      addUrl(raw['url']?.toString());
      addUrl(raw['src']?.toString());
      addUrl(raw['image']?.toString());
      addUrl(raw['guid']?.toString());
      out.addAll(_parseUrls(raw['items'] ?? raw['images'] ?? raw['gallery']));
      return out;
    }

    addUrl(raw.toString());
    return out;
  }

  List<String> _unique(List<String> urls) {
    final seen = <String>{};
    final out = <String>[];
    for (final u in urls) {
      final s = u.trim();
      if (s.isEmpty) continue;
      if (!(s.startsWith('http://') || s.startsWith('https://'))) continue;
      if (seen.add(s)) out.add(s);
    }
    return out;
  }

  // ============================
  //  EXTRAER IMÁGENES DEL JSON
  // ============================
  List<String> _extractImages(dynamic data) {
    if (data is! Map) return const [];

    // posibles llaves (en tu backend pueden variar)
    final candidates = <dynamic>[
      data['img_medium'],
      data['img_high'],
      data['img_full'],
      data['images'],
      data['gallery'],
      data['galeria'],
      data['fotos'],
      data['photos'],
      data['imgs'],
      data['imagenes'],
      data['media'],
      data['img'], // a veces viene como string o list
      // anidado
      (data['data'] is Map) ? (data['data'] as Map)['img_medium'] : null,
      (data['data'] is Map) ? (data['data'] as Map)['gallery'] : null,
      (data['data'] is Map) ? (data['data'] as Map)['images'] : null,
    ];

    final all = <String>[];
    for (final c in candidates) {
      all.addAll(_parseUrls(c));
    }
    return _unique(all);
  }

  // ============================
  //  GET_PUNTO -> LISTA DE IMÁGENES
  // ============================
  Future<List<String>> _fetchImages({
    required Dio dio,
    required int placeId,
    required String lang,
    required NowPlayingState now,
  }) async {
    try {
      // print (no debugPrint) para que SIEMPRE salga en consola
      // ignore: avoid_print
      print('🎧 MINI_PLAYER get_punto => id=$placeId lang=$lang');

      final resp = await dio.get(
        '/get_punto',
        queryParameters: {'post_id': placeId, 'lang': lang},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      final data = resp.data;

      if (data is Map) {
        // ignore: avoid_print
        print('🎧 MINI_PLAYER get_punto keys => ${data.keys.toList()}');
      }

      final extracted = _extractImages(data);

      // fallback: si tu endpoint NO manda imágenes, usa las del provider
      final fallback = _unique([
        ...now.images,
        if ((now.imageUrl ?? '').trim().isNotEmpty) now.imageUrl!.trim(),
      ]);

      final result = extracted.isNotEmpty ? extracted : fallback;

      // ignore: avoid_print
      print(
        '🎧 MINI_PLAYER images => extracted=${extracted.length} fallback=${fallback.length} final=${result.length}',
      );

      return result;
    } catch (e) {
      // ignore: avoid_print
      print('❌ MINI_PLAYER get_punto ERROR => $e');

      return _unique([
        ...now.images,
        if ((now.imageUrl ?? '').trim().isNotEmpty) now.imageUrl!.trim(),
      ]);
    }
  }

  Future<List<String>> _getImagesFuture({
    required Dio dio,
    required int placeId,
    required String lang,
    required NowPlayingState now,
  }) {
    final key = '$placeId|$lang|${now.title}';
    if (_cacheKey == key && _imagesFuture != null) return _imagesFuture!;
    _cacheKey = key;
    _imagesFuture = _fetchImages(
      dio: dio,
      placeId: placeId,
      lang: lang,
      now: now,
    );
    return _imagesFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowPlayingProvider);
    final notifier = ref.read(nowPlayingProvider.notifier);
    final dio = ref.watch(dioProvider);

    if (!now.hasAudio) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final bottomSafe = media.padding.bottom;

    // evita mini player gigante por accesibilidad
    final fixedMedia = media.copyWith(textScaler: const TextScaler.linear(1.0));

    final int? placeId = now.placeId ?? now.place?.id;
    final String lang = context.locale.languageCode;

    return MediaQuery(
      data: fixedMedia,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: FutureBuilder<List<String>>(
            future: (placeId == null)
                ? Future.value(
                    _unique([
                      ...now.images,
                      if ((now.imageUrl ?? '').trim().isNotEmpty)
                        now.imageUrl!.trim(),
                    ]),
                  )
                : _getImagesFuture(
                    dio: dio,
                    placeId: placeId,
                    lang: lang,
                    now: now,
                  ),
            builder: (context, snap) {
              final urls = snap.data ?? const <String>[];

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: (_) => _dragDy = 0,
                onVerticalDragUpdate: (d) => _dragDy += d.delta.dy,
                onVerticalDragEnd: (_) async {
                  if (_dragDy > 24) await notifier.clear();
                  _dragDy = 0;
                },
                onTap: () => _openFull(context, urls),
                child: Container(
                  height: 64,
                  margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomSafe + 64),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101010),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        offset: Offset(0, 8),
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _MiniCoverCarousel(
                        controller: _miniCoverCtrl,
                        urls: urls,
                        onPage: (i) {
                          if (!mounted) return;
                          setState(() => _miniPage = i);
                        },
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          now.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      IconButton(
                        tooltip: now.isPlaying ? 'Pausar' : 'Reproducir',
                        icon: Icon(
                          now.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                          color: now.isBusy ? Colors.white38 : Colors.white,
                        ),
                        onPressed: now.isBusy ? null : () => notifier.toggle(),
                      ),

                      IconButton(
                        tooltip: 'Cerrar',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => notifier.clear(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openFull(BuildContext context, List<String> urls) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FullPlayerBottomSheet(images: urls),
    );
  }
}

class _MiniCoverCarousel extends StatelessWidget {
  final PageController controller;
  final List<String> urls;
  final ValueChanged<int> onPage;

  const _MiniCoverCarousel({
    required this.controller,
    required this.urls,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: urls.isEmpty
            ? _miniPlaceholder()
            : PageView.builder(
                controller: controller,
                itemCount: urls.length,
                onPageChanged: onPage,
                physics: urls.length > 1
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemBuilder: (_, i) {
                  return Image.network(
                    urls[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _miniPlaceholder(),
                  );
                },
              ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      color: Colors.white10,
      alignment: Alignment.center,
      child: const Icon(Icons.museum_rounded, color: Colors.white, size: 20),
    );
  }
}

class _FullPlayerBottomSheet extends ConsumerStatefulWidget {
  final List<String> images;
  const _FullPlayerBottomSheet({required this.images});

  @override
  ConsumerState<_FullPlayerBottomSheet> createState() =>
      _FullPlayerBottomSheetState();
}

class _FullPlayerBottomSheetState
    extends ConsumerState<_FullPlayerBottomSheet> {
  final PageController _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowPlayingProvider);
    final audio = ref.watch(audioPlayerProvider);
    final notifier = ref.read(nowPlayingProvider.notifier);

    final dur = audio.duration ?? Duration.zero;
    final pos = audio.position;

    final maxMs = dur.inMilliseconds == 0 ? 1 : dur.inMilliseconds;
    final valueMs = pos.inMilliseconds.clamp(0, maxMs).toDouble();

    final images = widget.images;

    if (_index >= images.length) _index = 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              if (images.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _page,
                          itemCount: images.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          physics: images.length > 1
                              ? const PageScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, i) {
                            final url = images[i];
                            return Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white10,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.white54,
                                ),
                              ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.white10,
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
                            );
                          },
                        ),

                        // indicador 1/3 arriba a la derecha
                        if (images.length > 1)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_index + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                if (images.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 12 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              Text(
                now.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: valueMs,
                  max: maxMs.toDouble(),
                  onChanged: (v) =>
                      audio.seek(Duration(milliseconds: v.toInt())),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(pos),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    _fmt(dur),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              IconButton(
                iconSize: 72,
                icon: Icon(
                  now.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: now.isBusy ? Colors.white38 : Colors.white,
                ),
                onPressed: now.isBusy ? null : () => notifier.toggle(),
              ),

              const SizedBox(height: 10),

              TextButton.icon(
                onPressed: () async {
                  await notifier.clear();
                  if (mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.stop, color: Colors.white70, size: 16),
                label: const Text(
                  'Detener audio',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
