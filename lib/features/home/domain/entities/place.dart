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

  final List<String> imgThumb;
  final List<String> imgMedium;

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
    this.audio = "",
  });
}
