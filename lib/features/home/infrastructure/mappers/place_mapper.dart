import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';

class PlaceMapper {
  static PlaceEntity jsonToEntity(Map<String, dynamic> json) => PlaceEntity(
    id: json['id'] ?? 0,
    titulo: json['titulo'] ?? '',
    publicado: json['publicado'], // puede ser null
    descCorta: json['desc_corta'] ?? '',
    descLarga: json['desc_larga'] ?? '',
    latitud: json['latitud'] ?? '',
    longitud: json['longitud'] ?? '',
    tipo: json['tipo'] ?? '',
    tipoId: json['tipo_id'] ?? 0,
    tipoIcono: json['tipo_icono'] ?? '',
    tipoPin: json['tipo_pin'], // opcional
    tipoColor: json['tipo_color'], // opcional
    imagen: json['imagen'] ?? '',
    imagenHigh: json['imagen_high'] ?? '',
    imgThumb:
        (json['img_thumb'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    imgMedium:
        (json['img_medium'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
  );

  static List<PlaceEntity> jsonToList(List<dynamic> jsonList) =>
      jsonList.map((e) => jsonToEntity(e)).toList();
}

extension PlaceEntityJson on PlaceEntity {
  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'desc_corta': descCorta,
    'desc_larga': descLarga,
    'latitud': latitud,
    'longitud': longitud,
    'tipo': tipo,
    'tipo_id': tipoId,
    'tipo_icono': tipoIcono,
    'imagen': imagen,
    'imagen_high': imagenHigh,
    // agrega los opcionales si quieres persistir todo
  };

  static PlaceEntity fromJson(Map<String, dynamic> json) {
    return PlaceMapper.jsonToEntity(json);
  }
}
