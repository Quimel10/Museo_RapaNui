class BannerEntity {
  final int id;
  final String titulo;
  final String img;
  final String tipo;
  final String? destino;
  final String? popup;

  BannerEntity({
    required this.titulo,
    required this.id,
    required this.img,
    required this.tipo,
    this.destino,
    this.popup,
  });
}
