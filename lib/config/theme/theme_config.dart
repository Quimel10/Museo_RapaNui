import 'package:flutter/material.dart';

class AppColors {
  // === PALETA ORIGINAL (LEGACY) ===
  // Las dejamos por compatibilidad, pero en la práctica
  // la interfaz usará los nuevos colores oscuros de abajo.

  // principales
  static const Color bluePrimaryDark = Color(0xFF21527D);
  static const Color bluePrimaryLight = Color(0xFF1C9FE2);
  static const Color orangePrimary = Color(0xFFF3771D);

  // degradados
  static const Color blue = Color(0xFF0E4E78);
  static const Color blueDeep = Color(0xFF0B3C5A);

  // 👇 ANTES era beige de pergamino, ahora lo alineamos al panel oscuro
  static const Color cream = Color(0xFF151515);
  static const Color coral = Color(0xFFFF6F59);

  // Extras para “agua”
  static const Color aqua = Color(0xFF0D7AA3);
  static const Color cyanSoft = Color(0xFF78C9E2);

  // === NUEVA PALETA TIPO LOUVRE (NEGRO) ===
  //
  // Usamos negro de fondo y grises oscuros para paneles,
  // con texto en blanco, imitando la app de referencia.

  /// Fondo general de la app (equivalente al pergamino viejo)
  static const Color parchment = Color(0xFF000000); // negro puro

  /// Textos y neutros en tema oscuro
  static const Color neutral900 = Color(0xFF000000); // fondo principal
  static const Color neutral800 = Color(0xFF111111); // app bar / barras
  static const Color neutral700 = Color(0xFF888888); // textos secundarios
  static const Color neutral100 = Color(0xFFE0E0E0); // textos claros
  static const Color neutral50 = Color(0xFFFFFFFF); // blanco total

  /// Paneles / tarjetas principales
  static const Color panel = Color(0xFF151515); // tarjetas, bottom bar
  static const Color panelDark = Color(0xFF212121); // hover / bordes

  /// Vinotinto -> ahora lo alineamos a panel oscuro para no desentonar
  static const Color panelWine = panel; // mismo que panel
  static const Color panelWineDark = panelDark; // mismo que panelDark

  /// Texto genérico principal (fuera de paneles)
  static const Color textPrimary = neutral50; // blanco

  /// Texto sobre botones/paneles oscuros
  static const Color textOnPanel = neutral50; // blanco

  // Estados (los dejamos iguales, por si se usan en alerts, etc.)
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  // Complementarios antiguos (se mantienen por compatibilidad)
  static const Color aquaLight = Color(0xFFC9ECF5);
  static const Color pink = Color(0xFFE7A7A0);
  static const Color pinkLight = Color(0xFFF8E1DE);

  // 👇 ANTES ERA PERGAMINO (0xFFF3EFE2). AHORA ES PANEL OSCURO.
  static const Color sandLight = Color(0xFF151515);

  static const Color desertAmber = Color(0xFFCE9100);
}

class AppRadius {
  static const double xl = 16;
  static const double lg = 12;
  static const double md = 10;
  static const double sm = 8;
}

class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}
