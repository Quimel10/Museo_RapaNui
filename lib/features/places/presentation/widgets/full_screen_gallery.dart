// lib/features/places/presentation/widgets/full_screen_gallery.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(
      0,
      (widget.images.length - 1).clamp(0, 999999),
    );
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ GALERÍA PRO (pinch, doble tap, pan suave, sin "cuadro" fijo)
          PhotoViewGallery.builder(
            pageController: _controller,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _index = i),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) {
              final expected = event?.expectedTotalBytes;
              final loaded = event?.cumulativeBytesLoaded ?? 0;
              final progress = (expected == null || expected == 0)
                  ? null
                  : loaded / expected;

              return Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              );
            },
            builder: (context, index) {
              final url = images[index];

              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(url),
                // ✅ “ver la pieza bien” → que la imagen se adapte y puedas acercar sin límites raros
                minScale: PhotoViewComputedScale.contained,
                initialScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3.2,
                heroAttributes: PhotoViewHeroAttributes(tag: 'gallery_$url'),
                // ✅ suaviza el gesto y evita “saltos”
                filterQuality: FilterQuality.high,
              );
            },
          ),

          // ✅ cerrar (mejor UX: arriba izquierda como foto nativa)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),

          // ✅ indicador arriba al centro
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  "${_index + 1}/${images.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
