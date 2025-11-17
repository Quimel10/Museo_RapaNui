class PlaceEntity {
  final int id;
  final String titulo;
  final String? publicado; // 👈 opcional
  final String descCorta;
  final String descLarga; // 👈 opcional
  final String latitud;
  final String longitud;
  final String tipo;
  final int tipoId;
  final String tipoIcono;
  final String? tipoPin; // 👈 opcional
  final String? tipoColor; // 👈 opcional
  final String imagen;
  final String imagenHigh;
  final List<String> imgThumb; // 👈 opcional pero mejor lista vacía
  final List<String> imgMedium; // 👈 opcional pero mejor lista vacía

  PlaceEntity({
    required this.id,
    required this.titulo,
    this.publicado,
    required this.descCorta,
    required this.descLarga,
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
  });
}
