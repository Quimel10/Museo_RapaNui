// lib/shared/audio/now_playing_player.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio/dio.dart';

import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';
import 'package:disfruta_antofagasta/shared/provider/dio_provider.dart';

/// ✅ Mini reproductor
/// - Swipe horizontal SOLO en la mini imagen = carrusel
/// - Swipe hacia abajo en la barra = cerrar (clear)
class NowPlayingMiniBar extends ConsumerStatefulWidget {
  const NowPlayingMiniBar({super.key});

  @override
  ConsumerState<NowPlayingMiniBar> createState() => _NowPlayingMiniBarState();
}

class _NowPlayingMiniBarState extends ConsumerState<NowPlayingMiniBar> {
  final PageController _miniCoverCtrl = PageController();
  int _miniPage = 0;

  double _dragDy = 0;

  // cache para no re-pedir extras en loop
  String? _extrasKey;
  Future<_PieceExtras>? _extrasFuture;

  @override
  void dispose() {
    _miniCoverCtrl.dispose();
    super.dispose();
  }

  String _trOr(String key, String fallback) {
    final v = tr(key);
    return (v == key) ? fallback : v;
  }

  // ============================
  //  PARSER ROBUSTO DE IMÁGENES
  // ============================
  List<String> _parseUrls(dynamic raw) {
    final out = <String>[];

    void add(String? u) {
      final s = (u ?? '').trim();
      if (s.isEmpty) return;
      if (!(s.startsWith('http://') || s.startsWith('https://'))) return;
      out.add(s);
    }

    if (raw == null) return out;

    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          add(item);
        } else if (item is Map) {
          add(item['url']?.toString());
          add(item['src']?.toString());
          add(item['image']?.toString());
          add(item['guid']?.toString());
          add(item['link']?.toString());
        } else {
          add(item?.toString());
        }
      }
      return out;
    }

    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return out;

      if (s.startsWith('http://') || s.startsWith('https://')) {
        add(s);
        return out;
      }

      // a veces viene separado por coma o |
      final parts = s.contains('|') ? s.split('|') : s.split(',');
      for (final p in parts) {
        add(p);
      }
      return out;
    }

    if (raw is Map) {
      add(raw['url']?.toString());
      add(raw['src']?.toString());
      add(raw['image']?.toString());
      add(raw['guid']?.toString());
      out.addAll(_parseUrls(raw['items'] ?? raw['images'] ?? raw['gallery']));
      return out;
    }

    add(raw.toString());
    return out;
  }

  /// ✅ Normaliza para deduplicar:
  /// - Ignora scheme (http/https)
  /// - Host en minúsculas y sin www.
  /// - Quita query/fragment
  /// - Quita -scaled
  /// - Quita sufijos WP de tamaño -1024x768 (SIN romper el nombre)
  String _normalizeUrlKey(String url) {
    final s = url.trim();
    if (s.isEmpty) return s;

    Uri? u;
    try {
      u = Uri.parse(s);
    } catch (_) {
      u = null;
    }

    if (u != null &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.isNotEmpty) {
      var host = u.host.toLowerCase();
      if (host.startsWith('www.')) host = host.substring(4);

      // sin query/fragment
      final path = u.path;

      // normalizamos SOLO el último segmento (filename)
      final segments = path.split('/');
      if (segments.isNotEmpty) {
        final last = segments.removeLast();
        final fixedLast = _normalizeFilename(last);
        segments.add(fixedLast);
      }

      final normalizedPath = segments.join('/');
      // key sin scheme, sin query
      return '$host$normalizedPath';
    }

    // fallback (string)
    final noQuery = s.split('?').first.split('#').first;
    // intenta normalizar el filename al final
    final idx = noQuery.lastIndexOf('/');
    if (idx == -1) return _normalizeFilename(noQuery);
    final head = noQuery.substring(0, idx);
    final tail = noQuery.substring(idx + 1);
    return '$head/${_normalizeFilename(tail)}'.toLowerCase();
  }

  /// Quita variantes WP del filename:
  /// - foo-scaled.jpg => foo.jpg
  /// - foo-1024x768.jpg => foo.jpg
  /// - foo-scaled-1024x768.jpg => foo.jpg
  String _normalizeFilename(String filename) {
    var f = filename;

    // separa ext
    final m = RegExp(r'^(.*?)(\.[A-Za-z0-9]+)$').firstMatch(f);
    if (m == null) return f;

    var base = m.group(1) ?? '';
    final ext = m.group(2) ?? '';

    // quita -scaled al final del base
    base = base.replaceAll(RegExp(r'(-scaled)$'), '');

    // quita -WxH al final del base (WP sizes)
    base = base.replaceAll(RegExp(r'(-\d{2,5}x\d{2,5})$'), '');

    // por si viene encadenado (scaled luego size)
    base = base.replaceAll(RegExp(r'(-scaled)$'), '');
    base = base.replaceAll(RegExp(r'(-\d{2,5}x\d{2,5})$'), '');

    return '$base$ext';
  }

  List<String> _uniqueByKey(List<String> urls) {
    final seen = <String>{};
    final out = <String>[];

    for (final u in urls) {
      final s = u.trim();
      if (s.isEmpty) continue;
      if (!(s.startsWith('http://') || s.startsWith('https://'))) continue;

      final key = _normalizeUrlKey(s);
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  List<String> _extractImagesFromGetPunto(dynamic data) {
    if (data is! Map) return const [];

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
      data['img'],
      (data['data'] is Map) ? (data['data'] as Map)['img_medium'] : null,
      (data['data'] is Map) ? (data['data'] as Map)['gallery'] : null,
      (data['data'] is Map) ? (data['data'] as Map)['images'] : null,
    ];

    final all = <String>[];
    for (final c in candidates) {
      all.addAll(_parseUrls(c));
    }
    return _uniqueByKey(all);
  }

  Future<_PieceExtras> _loadExtras({
    required Dio dio,
    required int placeId,
    required String lang,
  }) async {
    try {
      final resp = await dio.get(
        '/get_punto',
        queryParameters: {'post_id': placeId, 'lang': lang},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      final data = resp.data;
      final imgs = _extractImagesFromGetPunto(data);

      final d1 =
          (data is Map ? (data['desc_larga_html'] ?? '') : '')?.toString() ??
          '';
      final d2 =
          (data is Map ? (data['desc_larga'] ?? '') : '')?.toString() ?? '';
      final desc = (d1.trim().isNotEmpty) ? d1.trim() : d2.trim();

      return _PieceExtras(images: imgs, descHtml: desc);
    } catch (_) {
      return const _PieceExtras(images: [], descHtml: '');
    }
  }

  Future<_PieceExtras> _getExtrasFuture({
    required Dio dio,
    required int placeId,
    required String lang,
  }) {
    final key = '$placeId|$lang';
    if (_extrasKey == key && _extrasFuture != null) return _extrasFuture!;
    _extrasKey = key;
    _extrasFuture = _loadExtras(dio: dio, placeId: placeId, lang: lang);
    return _extrasFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    if (!nowPlaying.hasAudio) return const SizedBox.shrink();

    final PlaceEntity? place = nowPlaying.place;
    final audio = ref.watch(audioPlayerProvider);
    final notifier = ref.read(nowPlayingProvider.notifier);
    final dio = ref.watch(dioProvider);

    final String cover = (place != null && place.imagenHigh.isNotEmpty)
        ? place.imagenHigh
        : (nowPlaying.imageUrl ?? '');

    final int? placeId = nowPlaying.placeId ?? place?.id;
    final String lang = context.locale.languageCode;

    final bottomPad = MediaQuery.of(context).padding.bottom;
    const navApprox = 56.0;
    const extraLift = 2.0;
    final safeBottom = bottomPad + navApprox + extraLift;

    final extrasFuture = (placeId == null)
        ? Future.value(const _PieceExtras(images: [], descHtml: ''))
        : _getExtrasFuture(dio: dio, placeId: placeId, lang: lang);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(left: 12, right: 12, bottom: safeBottom),
        child: FutureBuilder<_PieceExtras>(
          future: extrasFuture,
          builder: (context, snap) {
            final extras =
                snap.data ?? const _PieceExtras(images: [], descHtml: '');

            final urls = _uniqueByKey([
              ...((nowPlaying.images) ?? const <String>[]),
              if (cover.trim().isNotEmpty) cover.trim(),
              ...extras.images,
            ]);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _dragDy = 0,
              onVerticalDragUpdate: (d) => _dragDy += d.delta.dy,
              onVerticalDragEnd: (_) async {
                if (_dragDy > 24) {
                  await notifier.clear();
                }
                _dragDy = 0;
              },
              onTap: () => _openFullPlayer(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF101010),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
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
                    StreamBuilder<PlayerState>(
                      stream: audio.playerStateStream,
                      builder: (context, snapshot) {
                        final ps = snapshot.data;
                        final isPlaying = ps?.playing ?? audio.isPlaying;

                        return IconButton(
                          iconSize: 26,
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            if (isPlaying) {
                              await notifier.pause();
                            } else {
                              await notifier.resume();
                            }
                          },
                        );
                      },
                    ),
                    IconButton(
                      iconSize: 22,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () async => notifier.clear(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) {
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
      borderRadius: BorderRadius.circular(8),
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
      child: const Icon(Icons.museum_rounded, color: Colors.white, size: 20),
    );
  }
}

class _PieceExtras {
  final List<String> images;
  final String descHtml;

  const _PieceExtras({required this.images, required this.descHtml});
}

class NowPlayingFullPlayerSheet extends ConsumerStatefulWidget {
  const NowPlayingFullPlayerSheet({super.key});

  @override
  ConsumerState<NowPlayingFullPlayerSheet> createState() =>
      _NowPlayingFullPlayerSheetState();
}

class _NowPlayingFullPlayerSheetState
    extends ConsumerState<NowPlayingFullPlayerSheet> {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  String? _extrasKey;
  Future<_PieceExtras>? _extrasFuture;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String _trOr(String key, String fallback) {
    final v = tr(key);
    return (v == key) ? fallback : v;
  }

  List<String> _parseUrls(dynamic raw) {
    final out = <String>[];

    void add(String? u) {
      final s = (u ?? '').trim();
      if (s.isEmpty) return;
      if (!(s.startsWith('http://') || s.startsWith('https://'))) return;
      out.add(s);
    }

    if (raw == null) return out;

    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          add(item);
        } else if (item is Map) {
          add(item['url']?.toString());
          add(item['src']?.toString());
          add(item['image']?.toString());
          add(item['guid']?.toString());
          add(item['link']?.toString());
        } else {
          add(item?.toString());
        }
      }
      return out;
    }

    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return out;

      if (s.startsWith('http://') || s.startsWith('https://')) {
        add(s);
        return out;
      }

      final parts = s.contains('|') ? s.split('|') : s.split(',');
      for (final p in parts) {
        add(p);
      }
      return out;
    }

    if (raw is Map) {
      add(raw['url']?.toString());
      add(raw['src']?.toString());
      add(raw['image']?.toString());
      add(raw['guid']?.toString());
      out.addAll(_parseUrls(raw['items'] ?? raw['images'] ?? raw['gallery']));
      return out;
    }

    add(raw.toString());
    return out;
  }

  String _normalizeFilename(String filename) {
    var f = filename;

    final m = RegExp(r'^(.*?)(\.[A-Za-z0-9]+)$').firstMatch(f);
    if (m == null) return f;

    var base = m.group(1) ?? '';
    final ext = m.group(2) ?? '';

    base = base.replaceAll(RegExp(r'(-scaled)$'), '');
    base = base.replaceAll(RegExp(r'(-\d{2,5}x\d{2,5})$'), '');
    base = base.replaceAll(RegExp(r'(-scaled)$'), '');
    base = base.replaceAll(RegExp(r'(-\d{2,5}x\d{2,5})$'), '');

    return '$base$ext';
  }

  String _normalizeUrlKey(String url) {
    final s = url.trim();
    if (s.isEmpty) return s;

    Uri? u;
    try {
      u = Uri.parse(s);
    } catch (_) {
      u = null;
    }

    if (u != null &&
        (u.scheme == 'http' || u.scheme == 'https') &&
        u.host.isNotEmpty) {
      var host = u.host.toLowerCase();
      if (host.startsWith('www.')) host = host.substring(4);

      final path = u.path;
      final segments = path.split('/');
      if (segments.isNotEmpty) {
        final last = segments.removeLast();
        segments.add(_normalizeFilename(last));
      }
      final normalizedPath = segments.join('/');

      return '$host$normalizedPath';
    }

    final noQuery = s.split('?').first.split('#').first;
    final idx = noQuery.lastIndexOf('/');
    if (idx == -1) return _normalizeFilename(noQuery);
    final head = noQuery.substring(0, idx);
    final tail = noQuery.substring(idx + 1);
    return '$head/${_normalizeFilename(tail)}'.toLowerCase();
  }

  List<String> _uniqueByKey(List<String> urls) {
    final seen = <String>{};
    final out = <String>[];

    for (final u in urls) {
      final s = u.trim();
      if (s.isEmpty) continue;
      if (!(s.startsWith('http://') || s.startsWith('https://'))) continue;

      final key = _normalizeUrlKey(s);
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  List<String> _extractImagesFromGetPunto(dynamic data) {
    if (data is! Map) return const [];

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
      data['img'],
      (data['data'] is Map) ? (data['data'] as Map)['img_medium'] : null,
      (data['data'] is Map) ? (data['data'] as Map)['gallery'] : null,
      (data['data'] is Map) ? (data['data'] as Map)['images'] : null,
    ];

    final all = <String>[];
    for (final c in candidates) {
      all.addAll(_parseUrls(c));
    }
    return _uniqueByKey(all);
  }

  Future<_PieceExtras> _loadExtras({
    required Dio dio,
    required int placeId,
    required String lang,
  }) async {
    try {
      final resp = await dio.get(
        '/get_punto',
        queryParameters: {'post_id': placeId, 'lang': lang},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      final data = resp.data;
      final imgs = _extractImagesFromGetPunto(data);

      final d1 =
          (data is Map ? (data['desc_larga_html'] ?? '') : '')?.toString() ??
          '';
      final d2 =
          (data is Map ? (data['desc_larga'] ?? '') : '')?.toString() ?? '';
      final desc = (d1.trim().isNotEmpty) ? d1.trim() : d2.trim();

      return _PieceExtras(images: imgs, descHtml: desc);
    } catch (_) {
      return const _PieceExtras(images: [], descHtml: '');
    }
  }

  Future<_PieceExtras> _getExtrasFuture({
    required Dio dio,
    required int placeId,
    required String lang,
  }) {
    final key = '$placeId|$lang';
    if (_extrasKey == key && _extrasFuture != null) return _extrasFuture!;
    _extrasKey = key;
    _extrasFuture = _loadExtras(dio: dio, placeId: placeId, lang: lang);
    return _extrasFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final nowPlaying = ref.watch(nowPlayingProvider);
    if (!nowPlaying.hasAudio) return const SizedBox.shrink();

    final PlaceEntity? place = nowPlaying.place;
    final audio = ref.watch(audioPlayerProvider);
    final dio = ref.watch(dioProvider);
    final notifier = ref.read(nowPlayingProvider.notifier);

    final duration = audio.duration ?? Duration.zero;

    final String cover = (place != null && place.imagenHigh.isNotEmpty)
        ? place.imagenHigh
        : (nowPlaying.imageUrl ?? '');

    final String descFromProvider = (nowPlaying.descriptionHtml ?? '').trim();
    final double topInset = MediaQuery.of(context).padding.top;

    final int? placeId = nowPlaying.placeId ?? place?.id;
    final String lang = context.locale.languageCode;

    final stopLabel = _trOr('piece_detail.stop_audio_button', 'Detener audio');
    final descTitle = _trOr('piece_detail.description_title', 'Descripción');

    final Future<_PieceExtras> extrasFuture = (placeId == null)
        ? Future.value(const _PieceExtras(images: [], descHtml: ''))
        : _getExtrasFuture(dio: dio, placeId: placeId, lang: lang);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: topInset + 34,
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
              child: FutureBuilder<_PieceExtras>(
                future: extrasFuture,
                builder: (context, snap) {
                  final extras =
                      snap.data ?? const _PieceExtras(images: [], descHtml: '');

                  final String descHtml = descFromProvider.isNotEmpty
                      ? descFromProvider
                      : extras.descHtml;

                  final urls = _uniqueByKey([
                    if (cover.trim().isNotEmpty) cover.trim(),
                    ...extras.images,
                    ...((nowPlaying.images) ?? const <String>[]),
                  ]);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (urls.isEmpty)
                          _fullPlaceholder()
                        else
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  PageView.builder(
                                    controller: _pageCtrl,
                                    itemCount: urls.length,
                                    onPageChanged: (i) =>
                                        setState(() => _page = i),
                                    physics: urls.length > 1
                                        ? const PageScrollPhysics()
                                        : const NeverScrollableScrollPhysics(),
                                    itemBuilder: (_, i) {
                                      return Image.network(
                                        urls[i],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _fullPlaceholder(),
                                      );
                                    },
                                  ),
                                  if (urls.length > 1)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 12,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.35,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: Colors.white10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(
                                              urls.length,
                                              (i) => AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                width: (i == _page) ? 18 : 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: (i == _page)
                                                      ? Colors.white
                                                      : Colors.white38,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
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
                        StreamBuilder<Duration>(
                          stream: audio.positionStream,
                          initialData: audio.position,
                          builder: (context, snapshot) {
                            final pos = snapshot.data ?? Duration.zero;
                            final effectiveDuration =
                                duration.inMilliseconds > 0 ? duration : pos;

                            final maxMs = effectiveDuration.inMilliseconds > 0
                                ? effectiveDuration.inMilliseconds
                                : 1;

                            final valueMs = pos.inMilliseconds
                                .clamp(0, maxMs)
                                .toDouble();

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
                                    value: valueMs,
                                    max: maxMs.toDouble(),
                                    onChanged: (v) {
                                      audio.seek(
                                        Duration(milliseconds: v.round()),
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _fmt(pos),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _fmt(effectiveDuration),
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
                                onPressed: () async => notifier.rewind10(),
                              ),
                              const SizedBox(width: 8),
                              StreamBuilder<PlayerState>(
                                stream: audio.playerStateStream,
                                builder: (context, snapshot) {
                                  final ps = snapshot.data;
                                  final isPlaying =
                                      ps?.playing ?? audio.isPlaying;

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
                                onPressed: () async => notifier.forward10(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton.icon(
                            onPressed: () async {
                              await notifier.clear();
                              if (context.mounted) Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.stop_rounded,
                              color: Colors.white70,
                            ),
                            label: Text(
                              stopLabel,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        if (descHtml.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            descTitle,
                            style: const TextStyle(
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
                  );
                },
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

  String _fmt(Duration d) {
    final totalSeconds = d.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}
