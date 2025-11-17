import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/place_card.dart';
import 'package:disfruta_antofagasta/features/places/presentation/state/place_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/favorite_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    // if (favorites.isEmpty) {
    //   return const Center(child: Text('No tienes favoritos aún'));
    // }

    // Suponiendo que ya tienes todos los lugares en memoria
    // Si no, necesitarás cargarlos por ID desde el backend
    final allPlaces = ref.watch(placeProvider).places ?? [];
    final favPlaces = allPlaces.where((p) => favorites.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.bluePrimaryDark,
      appBar: AppBar(
        title: const Text(
          'Tus Favoritos',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Text(
                'No tienes favoritos aún',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favPlaces.length,
              itemBuilder: (_, i) {
                final p = favPlaces[i];
                return PlaceCard(
                  place: p,
                  isFavorite: true,
                  onFavoriteTap: () {
                    ref.read(favoritesProvider.notifier).toggle(p.id);
                  },
                  onTap: () {
                    context.push('/place/${p.id}');
                  },
                );
              },
            ),
    );
  }
}
