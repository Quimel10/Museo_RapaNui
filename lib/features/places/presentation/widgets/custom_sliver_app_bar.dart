import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:flutter/material.dart';

class CustomSliverAppBar extends StatelessWidget {
  final String? imageUrl;
  final String? title;
  final bool? isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final Object? heroTag;
  final double expandedHeight;

  const CustomSliverAppBar({
    super.key,
    required this.imageUrl,
    this.isFavorite,
    required this.onFavoriteToggle,
    this.title,
    this.onBack,
    this.onShare,
    this.heroTag,
    this.expandedHeight = 320,
  });

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: scaffoldBg,
      expandedHeight: expandedHeight,
      automaticallyImplyLeading: false, // manejamos nuestro botón back
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsetsDirectional.only(
          start: 56,
          bottom: 12,
          end: 16,
        ),
        centerTitle: false,

        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            // Degradado para asegurar contraste de iconos y título
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                bottom: false, //
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back,
                        semanticLabel: 'Volver',
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                      Row(
                        children: [
                          if (onShare != null) ...[const SizedBox(width: 8)],
                          _FavoriteButton(
                            isFavorite: isFavorite ?? false,
                            onTap: onFavoriteToggle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    final child = (imageUrl != null && imageUrl!.isNotEmpty)
        ? Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            // Carga gradual + manejo de error sin libs extra:
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            },
            errorBuilder: (_, _, _) => Container(
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_rounded,
                size: 56,
                color: Colors.black38,
              ),
            ),
          )
        : Container(
            color: Colors.black12,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_rounded,
              size: 56,
              color: Colors.black38,
            ),
          );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: child);
    }
    return child;
  }
}

/// Botón circular con fondo semitransparente para buena legibilidad sobre foto.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.sandLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                10,
              ), // ≥44dp touch target con padding externo
              child: Icon(icon, color: Colors.black87, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de favorito con animación ligera y semántica accesible.
class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const _FavoriteButton({required this.isFavorite, required this.onTap});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late bool _fav;
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _fav = widget.isFavorite;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.9,
      upperBound: 1.05,
    );
  }

  @override
  void didUpdateWidget(covariant _FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() => _fav = widget.isFavorite);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = _fav ? Icons.favorite : Icons.favorite_border;

    return Semantics(
      button: true,
      toggled: _fav,
      label: _fav ? 'Quitar de favoritos' : 'Agregar a favoritos',
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapCancel: () => _ctrl.reverse(),
        onTapUp: (_) => _ctrl.reverse(),
        onTap: () {
          widget.onTap();
          setState(() => _fav = !_fav);
        },
        child: ScaleTransition(
          scale: _ctrl.drive(Tween(begin: 1.0, end: 1.05)),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.sandLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.redAccent, size: 20),
          ),
        ),
      ),
    );
  }
}
