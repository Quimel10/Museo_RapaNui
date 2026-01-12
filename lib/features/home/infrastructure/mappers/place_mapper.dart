import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';

class PlaceMapper {
  static PlaceEntity jsonToEntity(Map<String, dynamic> json) {
    List<String> _toList(dynamic v) {
      if (v == null) return [];

      if (v is List) {
        return v
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }

      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return [];
        if (s.contains(',')) {
          return s
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        return [s];
      }

      if (v is Map) {
        final url = v['url'];
        if (url is String && url.trim().isNotEmpty) return [url.trim()];

        final sizes = v['sizes'];
        if (sizes is Map) {
          for (final key in ['full', 'large', 'medium', 'thumbnail']) {
            final x = sizes[key];
            if (x is String && x.trim().isNotEmpty) return [x.trim()];
          }
        }

        for (final key in ['full', 'large', 'medium', 'thumbnail', 'src']) {
          final x = v[key];
          if (x is String && x.trim().isNotEmpty) return [x.trim()];
        }
      }

      return [];
    }

    List<String> _dedup(List<String> input) {
      final seen = <String>{};
      final out = <String>[];
      for (final u in input) {
        final x = u.trim();
        if (x.isEmpty) continue;
        if (seen.add(x)) out.add(x);
      }
      return out;
    }

    final thumb = <String>[
      ..._toList(json['img_thumb']),
      ..._toList(json['imgThumb']),
      ..._toList(json['thumb']),
      ..._toList(json['thumbnail']),
    ];

    final medium = <String>[
      ..._toList(json['img_medium']),
      ..._toList(json['imgMedium']),
      ..._toList(json['medium']),
      ..._toList(json['gallery']),
      ..._toList(json['galeria']),
      ..._toList(json['galeria_fotos']),
      ..._toList(json['galeriaFotos']),
      ..._toList(json['images']),
      ..._toList(json['imagenes']),
      // por si el backend manda estos nombres
      ..._toList(json['img_full']),
      ..._toList(json['imgFull']),
      ..._toList(json['full']),
      ..._toList(json['large']),
    ];

    return PlaceEntity(
      id: json['id'] ?? 0,
      titulo: json['titulo'] ?? '',
      publicado: json['publicado'],
      descCorta: json['desc_corta'] ?? '',
      descLarga: json['desc_larga'] ?? '',
      descLargaHtml: json['desc_larga_html'],
      latitud: json['latitud'] ?? '',
      longitud: json['longitud'] ?? '',
      tipo: json['tipo'] ?? '',
      tipoId: json['tipo_id'] ?? 0,
      tipoIcono: json['tipo_icono'] ?? '',
      tipoPin: json['tipo_pin'],
      tipoColor: json['tipo_color'],
      imagen: json['imagen'] ?? '',
      imagenHigh: json['imagen_high'] ?? '',
      audio: json['audio'] ?? '',
      imgThumb: _dedup(thumb),
      imgMedium: _dedup(medium),
    );
  }

  static List<PlaceEntity> jsonToList(List<dynamic> jsonList) =>
      jsonList.map((e) => jsonToEntity(Map<String, dynamic>.from(e))).toList();
}

extension PlaceEntityJson on PlaceEntity {
  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'desc_corta': descCorta,
    'desc_larga': descLarga,
    'desc_larga_html': descLargaHtml,
    'latitud': latitud,
    'longitud': longitud,
    'tipo': tipo,
    'tipo_id': tipoId,
    'tipo_icono': tipoIcono,
    'imagen': imagen,
    'imagen_high': imagenHigh,
    'audio': audio,
    'img_thumb': imgThumb,
    'img_medium': imgMedium,
  };

  static PlaceEntity fromJson(Map<String, dynamic> json) {
    return PlaceMapper.jsonToEntity(json);
  }
}
