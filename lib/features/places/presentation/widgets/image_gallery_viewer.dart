import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ImageGalleryViewer extends StatefulWidget {
  const ImageGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagBuilder, // opcional si usas Hero en la grilla
  });

  final List<String> imageUrls;
  final int initialIndex;
  final String Function(int index)? heroTagBuilder;

  @override
  State<ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<ImageGalleryViewer> {
  late final PageController _pageController;
  late int _index;
  final TransformationController _transformCtrl = TransformationController();
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _index);
    // Barra de estado clara sobre fondo negro
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _prev() {
    if (_index > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.imageUrls.length > 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Carrusel
              PageView.builder(
                controller: _pageController,
                physics: _scale > 1.001
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (i) {
                  setState(() {
                    _index = i;
                  });
                  // resetear zoom al cambiar de página
                  _resetZoom();
                },
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, i) {
                  final img = widget.imageUrls[i];

                  final imageWidget = InteractiveViewer(
                    transformationController: _transformCtrl,
                    minScale: 1.0,
                    maxScale: 4.0,
                    onInteractionUpdate: (details) {
                      final m = _transformCtrl.value;
                      // escala aproximada (columna 0,0 de la matriz)
                      final s = m.storage[0];
                      if ((s - _scale).abs() > 0.01) {
                        setState(() => _scale = s);
                      }
                    },
                    child: Center(
                      child: Image.network(
                        img,
                        fit: BoxFit.contain,
                        loadingBuilder: (c, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox.expand(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (c, e, st) {
                          return const SizedBox.expand(
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                                size: 64,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );

                  // Doble toque para zoom in/out rápido
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () {
                      if (_scale > 1.001) {
                        _resetZoom();
                      } else {
                        // acercar al 2x centrado
                        setState(() {
                          _transformCtrl.value = Matrix4.identity()
                            // ignore: deprecated_member_use
                            ..scale(2.0, 2.0);
                          _scale = 2.0;
                        });
                      }
                    },
                    child: widget.heroTagBuilder != null
                        ? Hero(
                            tag: widget.heroTagBuilder!(i),
                            child: imageWidget,
                          )
                        : imageWidget,
                  );
                },
              ),

              // Botón cerrar
              Positioned(
                top: 8,
                left: 8,
                child: _CircleIconButton(
                  icon: Icons.close,
                  semantic: 'Cerrar galería',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),

              // Controles Anterior/Siguiente
              if (hasMultiple) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: false,
                    child: Row(
                      children: [
                        // Zona izquierda: botón anterior
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: _CircleIconButton(
                                icon: Icons.chevron_left,
                                semantic: 'Imagen anterior',
                                onTap: _index == 0 ? null : _prev,
                                disabled: _index == 0,
                              ),
                            ),
                          ),
                        ),
                        // Zona derecha: botón siguiente
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _CircleIconButton(
                                icon: Icons.chevron_right,
                                semantic: 'Imagen siguiente',
                                onTap: _index == widget.imageUrls.length - 1
                                    ? null
                                    : _next,
                                disabled: _index == widget.imageUrls.length - 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Indicador inferior  "3 / 10"
                Positioned(
                  bottom: 16 + MediaQuery.of(context).padding.bottom,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.semantic,
    this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String semantic;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final enabled = !disabled && onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semantic,
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? Colors.black54 : Colors.black26,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
