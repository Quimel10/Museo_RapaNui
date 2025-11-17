import 'package:cached_network_image/cached_network_image.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/theme_config.dart';
// Ajusta el import a tu entidad real

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.onFavoriteTap,
    this.onFavorite = true,
    this.isFavorite = false,
    this.compact = false,
  });

  final PlaceEntity place;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;
  final bool onFavorite;
  final bool compact; // true: menos alto, excerpt 1 línea

  @override
  Widget build(BuildContext context) {
    final accent =
        hexToColor(place.tipoColor) ?? AppColors.aqua; // color de categoría

    return Semantics(
      button: true,
      label: place.titulo,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sandLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlaceImage(url: place.imagen, radius: 14),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 30.0),
                            child: Text(
                              place.titulo,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.bluePrimaryDark,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CategoryIcon(url: place.tipoIcono, color: accent),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  place.tipo,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.neutral700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            place.descCorta,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.neutral700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de favorito en la esquina superior derecha
              if (onFavorite)
                Positioned(
                  top: 1,
                  right: 1,
                  child: Material(
                    color: AppColors.sandLight,
                    child: IconButton(
                      onPressed: onFavoriteTap,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),

                      // Color del icono: naranja si es favorito; si no, uno con buen contraste
                      style: IconButton.styleFrom(
                        foregroundColor: isFavorite
                            ? AppColors.orangePrimary
                            : _iconColorFor(accent), // <- ver helper abajo
                        // sin fondo gris del tema
                        backgroundColor: AppColors.sandLight,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _iconColorFor(Color accent) {
    // Si el color de categoría es muy claro, usa gris 700 para que se vea.
    return (accent.computeLuminance() > 0.78) ? AppColors.neutral700 : accent;
  }
}

class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.url, this.radius = 14});
  final String url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 120,
        height: 82,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            Container(width: 120, height: 82, color: AppColors.neutral100),
        errorWidget: (_, _, _) => Container(
          width: 120,
          height: 82,
          color: AppColors.neutral100,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.url, required this.color});
  final String url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(35)),
      ),
      padding: const EdgeInsets.all(2),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          return Icon(Icons.photo_size_select_small, size: 14, color: color);
        },
      ),
    );
  }
}

Color? hexToColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var s = hex.replaceAll('#', '').replaceAll('0x', '');
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v == null ? null : Color(v);
}
