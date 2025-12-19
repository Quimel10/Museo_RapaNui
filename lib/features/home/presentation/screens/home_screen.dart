import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_provider.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/banner_error.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/banner_skeleton.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/category_pill.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/place_skeleton.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/uv.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:disfruta_antofagasta/shared/provider/api_client_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/auth_mode_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';
import 'package:disfruta_antofagasta/shared/session_manager.dart';
import 'package:disfruta_antofagasta/shared/session_flag.dart';
import 'package:disfruta_antofagasta/config/router/routes.dart';
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
    final lang = ref.read(languageProvider);
    await ref.read(homeProvider.notifier).refresh(lang);
  }

  late final PageController _placesPageController;
  int _currentPlacePage = 0;

  @override
  void initState() {
    super.initState();
    _placesPageController = PageController(viewportFraction: 0.92);
    _placesPageController.addListener(() {
      final page = _placesPageController.page;
      if (page == null) return;
      final newIndex = page.round();
      if (newIndex != _currentPlacePage && mounted) {
        setState(() => _currentPlacePage = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _placesPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final places = state.places ?? const <PlaceEntity>[];

    final screenWidth = MediaQuery.of(context).size.width;
    final double heroCardWidth = screenWidth * 0.86;
    final double heroCardHeight = 300;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'home.welcome'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Consumer(
          builder: (context, ref, _) => IconButton(
            tooltip: 'home.logout_tooltip'.tr(),
            icon: const Icon(Icons.logout, color: Colors.white, size: 22),
            onPressed: () async {
              SessionFlag.hasPersistedSession = false;
              await SessionManager.clearSession();
              await ref.read(authProvider.notifier).logoutUser();
              ref.read(authModeProvider.notifier).state = AuthMode.login;
              if (!context.mounted) return;
              context.go(AppPath.login);
            },
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final lang = ref.watch(languageProvider);
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: lang,
                    dropdownColor: AppColors.panel,
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

                      // ✅ NUEVOS IDIOMAS
                      DropdownMenuItem(
                        value: 'it',
                        child: Text(
                          '🇮🇹 IT',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'ja',
                        child: Text(
                          '🇯🇵 JA',
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
                if (state.weather!.uvMax != null) ...[
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      final uv = state.weather!.uvMax;
                      final level = uvToLevel(uv);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: level.color, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              state.weather!.temperatura,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              ' V. ${state.weather!.viento}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(level.icon, size: 16, color: level.color),
                                const SizedBox(width: 2),
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
            // =========================
            // 1) DESTACADOS
            // =========================
            Text(
              'home.featured'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            CategoryChipsList(
              items: state.categories ?? const [],
              selectedId: state.selectedCategoryId,
              onChanged: (cat) {
                ref.read(homeProvider.notifier).selectCategory(cat.id);
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
              SizedBox(
                height: heroCardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => Container(
                    width: heroCardWidth,
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ] else if (places.isNotEmpty) ...[
              SizedBox(
                height: heroCardHeight,
                child: PageView.builder(
                  controller: _placesPageController,
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final p = places[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(analyticsProvider)
                                .clickObject(
                                  p.id,
                                  meta: {'screen': 'Home', 'name': p.titulo},
                                );
                            context.push('/place/${p.id}');
                          },
                          child: Container(
                            width: heroCardWidth,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (p.imagenHigh.isNotEmpty)
                                  Image.network(
                                    p.imagenHigh,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(color: Colors.grey.shade800),
                                  )
                                else
                                  Container(color: Colors.grey.shade800),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.05),
                                        Colors.black.withOpacity(0.9),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            if (p.audio.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'home.no_audio'.tr(),
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            await ref
                                                .read(
                                                  nowPlayingProvider.notifier,
                                                )
                                                .playFromPlace(p);

                                            ref
                                                .read(analyticsProvider)
                                                .clickObject(
                                                  p.id,
                                                  meta: {
                                                    'screen': 'Home',
                                                    'name': p.titulo,
                                                    'action': 'play_home',
                                                  },
                                                );
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 28,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                p.titulo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                p.tipo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                p.descCorta,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              if (places.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(places.length, (i) {
                    final bool active = i == _currentPlacePage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 10 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
            ] else ...[
              Text(
                'home.no_featured'.tr(),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 28),

            // =========================
            // 2) BANNERS INFORMATIVOS
            // =========================
            Text(
              'home.info_banners'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (state.isLoadingBanners) const BannerSkeleton(),
            if (!state.isLoadingBanners && state.errorMessageBanner != null)
              BannerError(
                message: 'home.banner_load_error'.tr(),
                onRetry: _refreshDashboard,
              ),
            if (!state.isLoadingBanners &&
                state.errorMessageBanner == null &&
                (state.banners?.isNotEmpty ?? false))
              HomeBannerCarousel(
                items: state.banners!,
                onTap: (banner, index) {
                  ref
                      .read(analyticsProvider)
                      .clickBanner(
                        banner.id,
                        meta: {'screen': 'Home', 'name': banner.titulo},
                      );
                },
              ),
            if (!state.isLoadingBanners &&
                state.errorMessageBanner == null &&
                (state.banners?.isEmpty ?? true))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'home.no_banners'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
