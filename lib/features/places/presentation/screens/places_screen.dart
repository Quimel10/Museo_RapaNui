// lib/features/places/presentation/screens/places_root_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/category_pill.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/place_card.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/place_skeleton.dart';
import 'package:disfruta_antofagasta/features/places/presentation/state/place_provider.dart';
import 'package:disfruta_antofagasta/features/places/presentation/widgets/section_error.dart';
import 'package:disfruta_antofagasta/shared/provider/api_client_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/favorite_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Ajusta imports a tus paths reales

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Carga inicial: categorías + primera página
    Future.microtask(() async {
      await ref.read(placeProvider.notifier).loadCategories();
      await ref.read(placeProvider.notifier).getPlaces(page: 1);
    });
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final s = ref.read(placeProvider);
    if ((s.search?.isNotEmpty ?? false)) return;

    final pos = _scroll.position;
    final trigger = max(240, pos.viewportDimension * 0.20);
    if (pos.pixels >= pos.maxScrollExtent - trigger) {
      if (!s.isLoadingMore && s.hasMore) {
        ref
            .read(placeProvider.notifier)
            .getPlaces(
              categoryId: s.selectedCategoryId,
              page: (s.page ?? 1) + 1,
            );
      }
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(placeProvider.notifier).refresh();

    _searchCtrl.clear();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final text = v.trim();
      final s = ref.read(placeProvider);
      if (text.isEmpty) {
        ref
            .read(placeProvider.notifier)
            .getPlaces(categoryId: s.selectedCategoryId, page: 1);
      } else {
        ref
            .read(placeProvider.notifier)
            .getSearch(categoryId: s.selectedCategoryId, search: text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeProvider);
    final items = state.places ?? const <PlaceEntity>[];

    return Scaffold(
      backgroundColor: AppColors.bluePrimaryDark,

      appBar: AppBar(
        title: Text('Qué visitar', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // Buscar
            TextField(
              controller: _searchCtrl,
              autofocus: false,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: '¿Qué visitar?',
                prefixIcon: Icon(Icons.search),
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Filtro por categoría
            const SizedBox(height: 6),
            if (state.categories != null)
              CategoryChipsList(
                items: state.categories!,
                selectedId: state.selectedCategoryId,
                onChanged: (cat) {
                  ref
                      .read(analyticsProvider)
                      .clickCategory(
                        cat.id,
                        meta: {'screen': 'que visitar', 'name': cat.name},
                      );
                  ref
                      .read(placeProvider.notifier)
                      .getSearch(
                        categoryId: cat.id,
                        search: _searchCtrl.text.trim(),
                      );
                },
                padding: EdgeInsets.zero, // que parta más pegado a la izquierda
              ),

            const SizedBox(height: 12),

            // Estados
            if (state.isLoadingPlaces == true && items.isEmpty) ...[
              const PlaceSkeleton(),
              const SizedBox(height: 12),
              const PlaceSkeleton(),
            ] else if (state.isLoadingMore && items.isEmpty) ...[
              SectionError(
                message: 'no se han encontrado resultados con ese mombre',
                onRetry: () {
                  _searchCtrl.clear();
                  ref
                      .read(placeProvider.notifier)
                      .getPlaces(page: 1, categoryId: 0);
                },
              ),
            ] else ...[
              // Lista
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final p = items[i];
                  final isFav = ref.watch(favoritesProvider).contains(p.id);

                  return PlaceCard(
                    key: ValueKey(p.id),
                    place: p,
                    onTap: () {
                      ref
                          .read(analyticsProvider)
                          .clickObject(
                            p.id,
                            meta: {'screen': 'Que visitar', 'name': p.titulo},
                          );
                      FocusScope.of(context).unfocus();
                      context.push('/place/${p.id}');
                    },
                    onFavoriteTap: () {
                      ref.read(favoritesProvider.notifier).toggle(p.id);
                    },
                    isFavorite: isFav,
                  );
                },
              ),
              if (state.isLoadingMore == true) ...[
                const SizedBox(height: 12),
                const PlaceSkeleton(),
              ] else if (state.hasMore == false &&
                  (state.search?.isEmpty ?? true)) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Cargando todos los resultados',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.neutral700,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
