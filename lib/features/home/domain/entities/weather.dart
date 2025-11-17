class WeatherEntity {
  final String temperatura;
  final String maxima;
  final double? uvMax;
  final String minima;
  final String viento;
  final String climaIcono; // código del ícono (ej: "7")

  WeatherEntity({
    required this.temperatura,
    required this.maxima,
    required this.minima,
    this.uvMax,
    required this.viento,
    required this.climaIcono,
  });
}
