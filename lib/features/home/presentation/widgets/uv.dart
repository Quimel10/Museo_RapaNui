import 'package:flutter/material.dart';

class UvLevel {
  final String label; // "Bajo", "Moderado", etc.
  final Color color; // color de fondo de la chip
  final IconData icon; // icono representativo
  final String advice; // tip breve p/ tooltip
  const UvLevel(this.label, this.color, this.icon, this.advice);
}

UvLevel uvToLevel(double? uv) {
  if (uv == null) {
    return const UvLevel(
      '—',
      Colors.grey,
      Icons.wb_sunny_outlined,
      'Sin datos de UV',
    );
  }
  if (uv <= 2) {
    return const UvLevel(
      'Bajo',
      Colors.green,
      Icons.wb_sunny_outlined,
      'Protección mínima necesaria',
    );
  } else if (uv <= 5) {
    return const UvLevel(
      'Moderado',
      Colors.yellow,
      Icons.wb_sunny,
      'Bloqueador SPF 30+ y lentes',
    );
  } else if (uv <= 7) {
    return const UvLevel(
      'Alto',
      Colors.orange,
      Icons.wb_sunny,
      'SPF 30+, sombrero y sombra al mediodía',
    );
  } else if (uv <= 10) {
    return const UvLevel(
      'Muy alto',
      Colors.red,
      Icons.sunny,
      'SPF 50+, re-aplica cada 2h, evita 11–16h',
    );
  } else {
    return const UvLevel(
      'Extremo',
      Colors.purple,
      Icons.sunny_snowing,
      'Evita el sol, protección máxima',
    );
  }
}
