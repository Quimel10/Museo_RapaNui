// lib/features/places/presentation/screens/place_details_screen.dart

import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/features/places/presentation/widgets/audio_player_widget.dart';
import 'package:disfruta_antofagasta/features/places/presentation/widgets/full_screen_gallery.dart';
import 'package:disfruta_antofagasta/shared/audio/now_playing_player.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:easy_localization/easy_localization.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final String placeId;

  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _place;

  @override
  void initState() {
    super.initState();

    // 👇 Muy importante: esperar al primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlace();
    });
  }

  Future<void> _loadPlace() async {
    try {
      // idioma actual: es, en, fr, pt...
      final langCode = context.locale.languageCode;

      final dio = Dio(BaseOptions(baseUrl: Environment.apiUrl));

      final resp = await dio.get(
        '/get_punto',
        queryParameters: {'post_id': widget.placeId, 'lang': langCode},
      );

      if (!mounted) return;

      final data = resp.data;

      // esperamos un JSON tipo objeto (no lista, no string suelto)
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
    } catch (e, st) {
      debugPrint('ERROR get_punto: $e\n$st');

      if (!mounted) return;

      setState(() {
        _error = tr('piece_detail.load_error');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ Cargando
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ Error o no hay datos
    if (_error != null || _place == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Text(
              _error ?? tr('piece_detail.not_found'),
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // ✅ Datos OK
    final place = _place!;

    final String titulo = (place['titulo'] ?? '') as String;
    final String tipo = (place['tipo'] ?? '') as String;

    final String heroImage =
        (place['imagen_high'] ?? place['imagen'] ?? '') as String;

    final String descHtml =
        (place['desc_larga_html'] ?? place['desc_larga'] ?? '') as String;

    final String? audioUrl = (place['audio'] as String?)?.trim().isEmpty ?? true
        ? null
        : (place['audio'] as String);

    // Galería de imágenes
    final List<String> gallery = ((place['img_medium'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .where(
          (url) =>
              url.isNotEmpty &&
              (url.startsWith('http://') || url.startsWith('https://')),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 👉 Contenido principal scrollable
          CustomScrollView(
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
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tipo / categoría
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

                      // Audio
                      if (audioUrl != null) ...[
                        const SizedBox(height: 24),
                        AudioPlayerWidget(
                          audioUrl: audioUrl,
                          title: titulo,
                          subtitle: tipo,
                          imageUrl: heroImage,
                          descriptionHtml: descHtml,
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Descripción (título traducido)
                      Text(
                        tr('piece_detail.description_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // HTML de la descripción
                      Html(
                        data: descHtml,
                        style: {
                          '*': Style(
                            color: Colors.white,
                            fontSize: FontSize(14),
                          ),
                          'p': Style(margin: Margins.only(bottom: 12)),
                        },
                      ),

                      const SizedBox(height: 28),

                      // Galería
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

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 👉 Mini-reproductor global, fijo abajo
          const NowPlayingMiniBar(),
        ],
      ),
    );
  }
}
