import 'dart:async';
import 'dart:math';

import 'package:disfruta_antofagasta/config/router/routes.dart';
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/category_pill.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/place_card.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/place_skeleton.dart';
import 'package:disfruta_antofagasta/features/places/presentation/state/place_provider.dart';
import 'package:disfruta_antofagasta/features/places/presentation/widgets/section_error.dart';
import 'package:disfruta_antofagasta/shared/provider/api_client_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await ref
          .read(placeProvider.notifier)
          .initForLang(context.locale.languageCode);
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
    _searchCtrl.clear();
    await ref.read(placeProvider.notifier).refresh();
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

    final bool isSearching =
        _searchCtrl.text.trim().isNotEmpty ||
        (state.search?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.parchment,
      appBar: AppBar(
        backgroundColor: AppColors.parchment,
        elevation: 0,
        title: Text(
          'pieces.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            // BUSCADOR
            TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'pieces.search'.tr(),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // CATEGORÍAS
            if (state.categories != null) ...[
              CategoryChipsList(
                items: state.categories!,
                selectedId: state.selectedCategoryId,
                padding: EdgeInsets.zero,
                onChanged: (cat, _) {
                  // ✅ FIX REAL: solo contar si esto ES una selección nueva
                  final prevId = ref.read(placeProvider).selectedCategoryId;
                  final willSelect = prevId != cat.id;

                  if (willSelect) {
                    ref
                        .read(analyticsProvider)
                        .clickCategory(
                          cat.id,
                          meta: {'screen': 'Piezas', 'name': cat.name},
                        );
                  }

                  // selectCategory puede togglear; igual lo llamamos siempre
                  ref.read(placeProvider.notifier).selectCategory(cat.id);
                },
              ),
              const SizedBox(height: 12),
            ],

            // ESTADOS
            if (state.isLoadingPlaces == true && items.isEmpty) ...[
              const PlaceSkeleton(),
              const SizedBox(height: 12),
              const PlaceSkeleton(),
            ] else if (!isSearching && items.isEmpty) ...[
              SectionError(
                message: 'No se han encontrado piezas.',
                onRetry: () {
                  _searchCtrl.clear();
                  ref
                      .read(placeProvider.notifier)
                      .getPlaces(page: 1, categoryId: state.selectedCategoryId);
                },
              ),
            ] else if (isSearching && items.isEmpty) ...[
              SectionError(
                message: 'No se encontraron piezas con ese nombre.',
                onRetry: () {
                  _searchCtrl.clear();
                  ref
                      .read(placeProvider.notifier)
                      .getPlaces(page: 1, categoryId: state.selectedCategoryId);
                },
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return PlaceCard(
                    key: ValueKey(p.id),
                    place: p,
                    onTap: () {
                      ref
                          .read(analyticsProvider)
                          .clickObject(
                            p.id,
                            meta: {'screen': 'Piezas', 'name': p.titulo},
                          );
                      FocusScope.of(context).unfocus();

                      // ✅ ruta dentro del TAB PIEZAS (mantiene menú)
                      context.push('${AppPath.places}/place/${p.id}');
                    },
                  );
                },
              ),
              if (!isSearching && state.isLoadingMore == true) ...[
                const SizedBox(height: 12),
                const PlaceSkeleton(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
