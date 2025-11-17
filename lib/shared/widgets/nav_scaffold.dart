import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class NavScaffold extends ConsumerWidget {
  const NavScaffold({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider); // 👈 dependencia Riverpod

    const double barHeight = 68;
    const Color bg = AppColors.sandLight;
    const Color unselected = AppColors.bluePrimaryLight;
    const Color selected = AppColors.bluePrimaryDark;

    return Scaffold(
      backgroundColor: AppColors.sandLight,
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: Container(
        color: bg,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            height: barHeight,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? selected : unselected,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(color: isSelected ? selected : unselected);
            }),
          ),
          child: NavigationBar(
            key: ValueKey('nav-$lang'), // 👈 fuerza reconstrucción por idioma
            elevation: 0,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: tr('tabs.home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.terrain_outlined),
                selectedIcon: const Icon(Icons.terrain),
                label: tr('tabs.places'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.map_outlined),
                selectedIcon: const Icon(Icons.map),
                label: tr('tabs.map'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_border),
                selectedIcon: const Icon(Icons.favorite),
                label: tr('tabs.favorites'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
