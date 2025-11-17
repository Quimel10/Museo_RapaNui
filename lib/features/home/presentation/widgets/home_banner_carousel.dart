// lib/features/home/presentation/widgets/home_banner_carousel.dart
// Widget reutilizable para mostrar banners en Home.
// Soporta acción "Popup" (muestra imagen en modal) y "Link" (abre destino).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/banner.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, required this.items, this.onTap});

  final List<BannerEntity> items;
  final void Function(BannerEntity banner, int index)? onTap;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final _controller = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: widget.items.length,
            itemBuilder: (_, i) => _BannerItem(
              banner: widget.items[i],
              onPressed: () async {
                widget.onTap?.call(widget.items[i], i);
                await _handleTap(context, widget.items[i]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleTap(BuildContext context, BannerEntity b) async {
    final tipo = (b.tipo).toLowerCase();
    if (tipo == 'popup' && (b.popup?.isNotEmpty ?? false)) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => _BannerPopup(imageUrl: b.popup!, title: b.titulo),
      );
      return;
    }
    if ((b.destino?.isNotEmpty ?? false)) {
      final uri = Uri.tryParse(b.destino!);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

class _BannerItem extends StatelessWidget {
  const _BannerItem({required this.banner, required this.onPressed});
  final BannerEntity banner;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: banner.titulo,
              button: true,
              child: InkWell(
                onTap: onPressed,
                child: CachedNetworkImage(
                  imageUrl: banner.img,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppColors.neutral100),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.neutral100,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
              ),
            ),
            // Gradiente para mejor legibilidad si agregamos overlay más adelante
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerPopup extends StatelessWidget {
  const _BannerPopup({required this.imageUrl, this.title});
  final String imageUrl;
  final String? title;
  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.8;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: AppColors.bluePrimaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxH, // límite de alto (no recorta imagen)
          minWidth: double.infinity,
        ),
        child: Stack(
          children: [
            // Contenido scrolleable con padding inferior
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain, // se ve completa
                      width: double.infinity,
                      // --- CARGANDO ---
                      placeholder: (context, url) => Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24),
                        height: 200, // alto mínimo mientras carga
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // --- ERROR (opcional) ---
                      errorWidget: (_, _, _) => Container(
                        height: 200,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(10),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16, // da ancho para poder centrar
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Center(
                  child: FilledButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.bluePrimaryLight,
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white70),
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Entendido'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
