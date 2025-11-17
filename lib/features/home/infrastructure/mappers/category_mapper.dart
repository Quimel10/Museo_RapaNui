import 'package:disfruta_antofagasta/features/home/domain/entities/category.dart';

class CategoryMapper {
  static CategoryEntity jsonToEntity(Map<String, dynamic> json) =>
      CategoryEntity(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        nameEs: json['name_es'] ?? '',
        nameEn: json['name_en'] ?? '',
        icono: json['icono'] ?? '',
        iconoDefault: json['icono_default'] ?? '',
        imagen: json['imagen'] ?? '',
        color: json['color'] ?? '',
      );

  static List<CategoryEntity> jsonToList(List<dynamic> jsonList) =>
      jsonList.map((e) => jsonToEntity(e)).toList();
}
