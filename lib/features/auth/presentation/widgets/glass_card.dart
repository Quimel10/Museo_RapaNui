import 'package:flutter/material.dart';
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Tarjeta oscura sobre fondo negro (tipo Louvre)
        color: AppColors.panel.withOpacity(0.95),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.40),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Padding(
        padding: padding,
        // NO cambiamos DefaultTextStyle para no romper formularios
        child: child,
      ),
    );
  }
}
