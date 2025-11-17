import 'package:disfruta_antofagasta/features/home/domain/entities/weather.dart';

class WeatherMapper {
  static WeatherEntity jsonToEntity(Map<String, dynamic> json) => WeatherEntity(
    temperatura: json['temperaturas'] ?? '',
    maxima: json['maxima'] ?? '',
    minima: json['minima'] ?? '',
    uvMax: json['uv_max'],
    viento: json['viento'] ?? '',
    climaIcono: json['clima_icono']?.toString() ?? '',
  );
}
