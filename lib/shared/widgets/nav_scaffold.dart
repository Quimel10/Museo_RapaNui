// lib/shared/widgets/nav_scaffold.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class NavScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavScaffold({super.key, required this.navigationShell});

  void _onTap(int index) {
    final current = navigationShell.currentIndex;

    // ✅ CLAVE: si toca el MISMO tab, NO navegues.
    // Esto evita re-selección que a veces provoca pause/resume raro en cámara (Android).
    if (index == current) {
      return;
    }

    // ✅ Cambio normal de tab (NO resetear la rama)
    navigationShell.goBranch(index, initialLocation: false);
  }

  @override
  Widget build(BuildContext context) {
    // 👇 reconstruye BottomNavigationBar al cambiar idioma
    final localeKey = ValueKey(context.locale.toString());

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        key: localeKey,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.qr_code_scanner),
            label: 'tabs.scan'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: 'tabs.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const _SearchGridIcon(),
            label: 'tabs.search'.tr(),
          ),
        ],
      ),
    );
  }
}

/// Ícono personalizado de búsqueda
class _SearchGridIcon extends StatelessWidget {
  const _SearchGridIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.6),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(
            width: 10,
            height: 10,
            child: Wrap(
              spacing: 1.3,
              runSpacing: 1.3,
              children: List.generate(9, (_) {
                return Container(width: 2.2, height: 2.2, color: color);
              }),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 8,
                height: 2,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
