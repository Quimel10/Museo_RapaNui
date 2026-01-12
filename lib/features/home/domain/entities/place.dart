// lib/features/home/domain/entities/place.dart

class PlaceEntity {
  final int id;
  final String titulo;
  final String? publicado;
  final String descCorta;

  // Texto plano
  final String descLarga;

  // HTML desde WordPress (con <p>, <br>, <strong>, etc.)
  final String? descLargaHtml;

  final String latitud;
  final String longitud;
  final String tipo;
  final int tipoId;
  final String tipoIcono;
  final String? tipoPin;
  final String? tipoColor;

  final String imagen;
  final String imagenHigh;

  // ✅ Campos antiguos (NO se tocan)
  final List<String> imgThumb;
  final List<String> imgMedium;

  // ✅ NUEVO (para tu endpoint get_punto actual)
  // backend devuelve: img_large, img_full
  final List<String> imgLarge;
  final List<String> imgFull;

  final String audio;

  PlaceEntity({
    required this.id,
    required this.titulo,
    this.publicado,
    required this.descCorta,
    required this.descLarga,
    this.descLargaHtml,
    required this.latitud,
    required this.longitud,
    required this.tipo,
    required this.tipoId,
    required this.tipoIcono,
    this.tipoPin,
    this.tipoColor,
    required this.imagen,
    required this.imagenHigh,
    this.imgThumb = const [],
    this.imgMedium = const [],
    this.imgLarge = const [], // ✅ NUEVO
    this.imgFull = const [], // ✅ NUEVO
    this.audio = "",
  });

  // Helpers opcionales por si te sirven en la UI
  List<String> get galleryForListView {
    // preferimos large, luego medium, luego thumb
    if (imgLarge.isNotEmpty) return imgLarge;
    if (imgMedium.isNotEmpty) return imgMedium;
    return imgThumb;
  }

  List<String> get galleryForFullScreen {
    // preferimos full, luego large, luego medium
    if (imgFull.isNotEmpty) return imgFull;
    if (imgLarge.isNotEmpty) return imgLarge;
    return imgMedium;
  }
}
