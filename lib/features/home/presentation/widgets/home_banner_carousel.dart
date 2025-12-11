// lib/features/home/presentation/widgets/home_banner_carousel.dart
// Widget reutilizable para mostrar banners en Home.
// Muestra los banners EN VERTICAL (uno debajo de otro).
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
  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    // Estamos dentro de un ListView padre,
    // así que este ListView debe ser shrinkWrap y sin scroll propio.
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final banner = widget.items[index];

        return _BannerItem(
          banner: banner,
          onPressed: () async {
            // 1) Analytics (callback desde HomeScreen)
            widget.onTap?.call(banner, index);

            // 2) Acción del banner (popup / externo / nada)
            await _handleTap(context, banner);
          },
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context, BannerEntity b) async {
    // LOGS para depuración
    debugPrint(
      '[BANNER] TAP -> id=${b.id}, titulo=${b.titulo}, '
      'tipo=${b.tipo}, destino=${b.destino}, popup=${b.popup}',
    );

    final tipo = (b.tipo ?? '').trim().toLowerCase();
    final hasPopup = (b.popup?.isNotEmpty ?? false);
    final hasLink = (b.destino?.isNotEmpty ?? false);

    debugPrint(
      '[BANNER] Normalizado -> tipo="$tipo", hasPopup=$hasPopup, hasLink=$hasLink',
    );

    // POPUP explícito o inferido
    if (tipo == 'popup' || (tipo.isEmpty && hasPopup)) {
      debugPrint('[BANNER] Acción: MOSTRAR POPUP');
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => _BannerPopup(imageUrl: b.popup!, title: b.titulo),
      );
      return;
    }

    // LINK externo explícito o inferido
    if (tipo == 'externo' || (tipo.isEmpty && hasLink)) {
      debugPrint('[BANNER] Acción: ABRIR LINK EXTERNO -> ${b.destino}');
      final uri = Uri.tryParse(b.destino!);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[BANNER] ERROR: URL inválida -> ${b.destino}');
      }
      return;
    }

    // Nulo u otro tipo
    debugPrint('[BANNER] Acción: NINGUNA (tipo="$tipo")');
  }
}

// -----------------------------------------------------------
//  CARD VERTICAL DEL BANNER
// -----------------------------------------------------------
class _BannerItem extends StatelessWidget {
  const _BannerItem({required this.banner, required this.onPressed});

  final BannerEntity banner;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 140;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: cardHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InkWell(
              onTap: onPressed,
              child: CachedNetworkImage(
                imageUrl: banner.img,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.neutral100),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.neutral100,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.neutral700,
                  ),
                ),
              ),
            ),
            // Gradiente inferior para legibilidad del texto
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Título del banner
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  banner.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

// -----------------------------------------------------------
//  POPUP DEL BANNER
// -----------------------------------------------------------
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
        constraints: BoxConstraints(maxHeight: maxH, minWidth: double.infinity),
        child: Stack(
          children: [
            // Imagen scrolleable
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                children: [
                  if (title != null && title!.trim().isNotEmpty) ...[
                    Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      placeholder: (_, __) => Container(
                        height: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Botón cerrar
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),

            // Botón "Entendido"
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                top: false,
                child: Center(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.bluePrimaryLight,
                      ),
                      foregroundColor: WidgetStateProperty.all(Colors.white70),
                    ),
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
