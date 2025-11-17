import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_provider.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/banner_error.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/banner_skeleton.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/category_pill.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/place_card.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/place_skeleton.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/uv.dart';
import 'package:disfruta_antofagasta/shared/provider/api_client_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/auth_mode_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refreshDashboard() async {
    await ref.read(homeProvider.notifier).refresh(); // usa el lang actual
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final places = state.places ?? const <PlaceEntity>[];

    return Scaffold(
      backgroundColor: AppColors.bluePrimaryDark,
      appBar: AppBar(
        title: Text('home.welcome'.tr(), style: TextStyle(color: Colors.white)),
        leading: Consumer(
          builder: (context, ref, _) => IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            onPressed: () async {
              await ref.read(authProvider.notifier).logoutUser();
              ref.read(authModeProvider.notifier).state =
                  AuthMode.login; // o guest / register

              if (!context.mounted) return;
              context.pushReplacementNamed('login');
            },
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final lang = ref.watch(languageProvider);
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bluePrimaryDark, // Fondo azul del botón
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: lang,
                    // Menú desplegable con fondo azul oscuro
                    dropdownColor: AppColors.bluePrimaryDark,
                    // Ícono y texto en blanco
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'es',
                        child: Text(
                          '🇪🇸 ES',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(
                          '🇬🇧 EN',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'pt',
                        child: Text(
                          '🇧🇷 PT',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'fr',
                        child: Text(
                          '🇫🇷 FR',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    onChanged: (v) async {
                      if (v != null) {
                        await ref
                            .read(languageProvider.notifier)
                            .setLanguage(context, ref, v);
                      }
                    },
                  ),
                ),
              );
            },
          ),
          if (state.weather != null)
            Row(
              children: [
                // —— UV chip ——
                if (state.weather!.uvMax != null) ...[
                  const SizedBox(width: 10),
                  Builder(
                    builder: (context) {
                      final uv = state.weather!.uvMax; // double o num
                      final level = uvToLevel(uv);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sandLight.withValues(alpha: 0.80),
                          border: Border.all(color: level.color, width: 1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              state.weather!.temperatura,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              ' V. ${state.weather!.viento}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 10,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(level.icon, size: 16, color: level.color),
                                Text(
                                  'UV -',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: level.color,
                                  ),
                                ),

                                Text(
                                  level.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: level.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- Sección Banners ---
            if (state.isLoadingBanners) const BannerSkeleton(),
            if (!state.isLoadingBanners && state.errorMessageBanner != null)
              BannerError(
                message: state.errorMessageBanner!,
                onRetry: () => ref.read(homeProvider.notifier).loadBanners(),
              ),
            if (!state.isLoadingBanners &&
                state.errorMessageBanner == null &&
                (state.banners?.isNotEmpty ?? false))
              HomeBannerCarousel(
                items: state.banners!,
                onTap: (b, i) {
                  ref
                      .read(analyticsProvider)
                      .clickBanner(
                        b.id,
                        meta: {'screen': 'Home', 'name': b.titulo},
                      );
                  print(b.id);
                },
              ),
            if (!state.isLoadingBanners &&
                state.errorMessageBanner == null &&
                (state.banners?.isEmpty ?? true))
              const SizedBox.shrink(),

            const SizedBox(height: 14),
            Text(
              'Destacados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            CategoryChipsList(
              items: state.categories ?? const [],
              selectedId: state.selectedCategoryId,
              onChanged: (cat) {
                ref.read(homeProvider.notifier).selectCategory(cat.id);
                print('se le hizo click a ${cat.id}');

                ref
                    .read(analyticsProvider)
                    .clickCategory(
                      cat.id,
                      meta: {'screen': 'Home', 'name': cat.name},
                    );
              },
            ),
            const SizedBox(height: 14),

            if (state.isLoadingPlaces) ...[
              const PlaceSkeleton(),
              const SizedBox(height: 12),
              const PlaceSkeleton(),
              const SizedBox(height: 12),
              const PlaceSkeleton(),
            ] else ...[
              // Listado con un solo scroll (el del Home)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: places.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = places[i];

                  return PlaceCard(
                    key: ValueKey(p.id),
                    place: p,
                    onTap: () {
                      print('se le hizo click a $p.id');
                      ref
                          .read(analyticsProvider)
                          .clickObject(
                            p.id,
                            meta: {'screen': 'Home', 'name': p.titulo},
                          );
                      context.push('/place/${p.id}'); // o tu navegación
                    },
                    onFavorite: false,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
