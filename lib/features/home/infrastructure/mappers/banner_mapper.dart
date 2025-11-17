import 'package:disfruta_antofagasta/features/home/domain/entities/banner.dart';

class BannerMapper {
  static BannerEntity jsonToEntity(Map<String, dynamic> json) {
    final rawId = json['id'];

    return BannerEntity(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      titulo: (json['titulo'] ?? '').toString(),
      img: (json['img'] ?? json['imagen'] ?? '').toString(), // <--- AQUÍ EL FIX
      tipo: (json['tipo'] ?? '').toString(),
      destino: json['destino']?.toString(),
      popup: json['popup']?.toString(),
    );
  }

  static List<BannerEntity> jsonToList(dynamic data) {
    if (data is List) {
      return data
          .where((e) => e is Map<String, dynamic>)
          .map((e) => jsonToEntity(e))
          .toList();
    }
    return [];
  }
}
