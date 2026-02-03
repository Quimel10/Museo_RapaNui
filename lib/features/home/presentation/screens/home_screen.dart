// lib/features/home/presentation/screens/home_screen.dart
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_provider.dart';
import 'package:disfruta_antofagasta/features/home/presentation/state/home_boot_loader.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/banner_error.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/banner_skeleton.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/category_pill.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:disfruta_antofagasta/features/home/presentation/widgets/uv.dart';
import 'package:disfruta_antofagasta/shared/provider/api_client_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/auth_mode_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/language_notifier.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/available_languages_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/provider.dart'; // ✅ FIX: aquí vive analyticsProvider
import 'package:disfruta_antofagasta/shared/session_flag.dart';
import 'package:disfruta_antofagasta/shared/session_manager.dart';
import 'package:disfruta_antofagasta/config/router/routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:disfruta_antofagasta/shared/language_onboarding_gate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _refreshDashboard() async {
    final lang = ref.read(languageProvider);

    debugPrint('HOME REFRESH -> refresh(lang=$lang)');
    await ref.read(homeProvider.notifier).refresh(lang);
    debugPrint('HOME REFRESH -> DONE');
  }

  Future<void> _loadWithOverlay(
    String lang, {
    String message = 'Cargando contenido…',
  }) async {
    final boot = ref.read(homeBootLoaderProvider.notifier);
    boot.show(message);

    try {
      debugPrint('HOME OVERLAY LOAD -> refresh(lang=$lang)');

      // ✅ fuerza refetch de idiomas (por si WP cambió recien)
      ref.invalidate(availableLanguagesProvider);

      await ref.read(homeProvider.notifier).refresh(lang);

      // ✅ vuelve a invalidar para UI actualizada
      ref.invalidate(availableLanguagesProvider);

      debugPrint('HOME OVERLAY LOAD -> DONE');
    } finally {
      boot.hide();
    }
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      // ✅ fuerza refetch real
      ref.invalidate(availableLanguagesProvider);

      // ✅ leer idiomas disponibles desde WP
      final allowed = await ref.read(availableLanguagesProvider.future);

      await LanguageOnboardingGate.showOncePerSession(
        context,
        allowedCodes: allowed,
        initialCode: ref.read(languageProvider),
        onConfirm: (code) async {
          final changed = await ref
              .read(languageProvider.notifier)
              .setLanguage(context, code);

          if (changed) {
            await _loadWithOverlay(code, message: 'Cargando piezas…');
          }
        },
      );
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
    final boot = ref.watch(homeBootLoaderProvider);

    final availableAsync = ref.watch(availableLanguagesProvider);
    final currentLang = ref.watch(languageProvider);

    debugPrint(
      'HOME BUILD -> isLoadingPlaces=${state.isLoadingPlaces} places=${places.length}',
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final double heroCardWidth = screenWidth * 0.86;
    final double heroCardHeight = 300;

    // ✅ idiomas desde WP (si falla, fallback base)
    final availableLangs = availableAsync.maybeWhen(
      data: (v) => v.isEmpty ? const ['es', 'en', 'pt', 'fr', 'it'] : v,
      orElse: () => const ['es', 'en', 'pt', 'fr', 'it'],
    );

    // ✅ si current no existe en lista, normalizamos a es (evita dropdown crash)
    final safeCurrentLang = availableLangs.contains(currentLang)
        ? currentLang
        : 'es';

    // ✅ si hubo normalización, corregimos provider post-frame (solo una vez)
    if (safeCurrentLang != currentLang) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final changed = await ref
            .read(languageProvider.notifier)
            .setLanguage(context, safeCurrentLang);

        if (changed) {
          await _loadWithOverlay(safeCurrentLang, message: 'Cargando piezas…');
        }
      });
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'home.welcome'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            leading: Consumer(
              builder: (context, ref, _) => IconButton(
                tooltip: 'home.logout_tooltip'.tr(),
                icon: const Icon(Icons.logout, color: Colors.white, size: 22),
                onPressed: () async {
                  await LanguageOnboardingGate.resetSession();

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
                        value: safeCurrentLang,
                        dropdownColor: AppColors.panel,
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        items: availableLangs.map((code) {
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text(
                              _langLabel(code),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) async {
                          if (v == null) return;

                          final changed = await ref
                              .read(languageProvider.notifier)
                              .setLanguage(context, v);

                          if (changed) {
                            await _loadWithOverlay(
                              v,
                              message: 'Cargando piezas…',
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              if (state.weather != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                                    Icon(
                                      level.icon,
                                      size: 16,
                                      color: level.color,
                                    ),
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
            color: Colors.white,
            backgroundColor: Colors.black,
            onRefresh: _refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                  onChanged: (cat, _) {
                    final prevId = ref.read(homeProvider).selectedCategoryId;
                    final willSelect = prevId != cat.id;

                    if (willSelect) {
                      ref
                          .read(analyticsProvider)
                          .clickCategory(
                            cat.id,
                            meta: {'screen': 'Home', 'name': cat.name},
                          );
                    }

                    ref.read(homeProvider.notifier).selectCategory(cat.id);
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
                        return _HeroPlaceCard(
                          place: p,
                          width: heroCardWidth,
                          height: heroCardHeight,
                          onOpen: () {
                            ref
                                .read(analyticsProvider)
                                .clickObject(
                                  p.id,
                                  meta: {'screen': 'Home', 'name': p.titulo},
                                );
                            context.push('/place/${p.id}');
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (places.length > 1)
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(
                          places.length > 12 ? 12 : places.length,
                          (i) {
                            final active = i == _currentPlacePage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: active ? 10 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ] else ...[
                  Text(
                    'home.no_featured'.tr(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 28),
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        if (boot.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.78),
              child: Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 14),
                      Text(
                        boot.message.isEmpty ? 'Cargando…' : boot.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _langLabel(String code) {
    switch (code) {
      case 'es':
        return '🇪🇸 ES';
      case 'en':
        return '🇬🇧 EN';
      case 'pt':
        return '🇧🇷 PT';
      case 'fr':
        return '🇫🇷 FR';
      case 'it':
        return '🇮🇹 IT';
      case 'ja':
        return '🇯🇵 JA';
      default:
        return code.toUpperCase();
    }
  }
}

class _HeroPlaceCard extends ConsumerWidget {
  const _HeroPlaceCard({
    required this.place,
    required this.width,
    required this.height,
    required this.onOpen,
  });

  final PlaceEntity place;
  final double width;
  final double height;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = place;

    final nowPlaying = ref.watch(nowPlayingProvider);
    final notifier = ref.read(nowPlayingProvider.notifier);

    final audioUrl = p.audio.trim();

    final isActive =
        (nowPlaying.placeId == p.id) ||
        (audioUrl.isNotEmpty && (nowPlaying.url ?? '').trim() == audioUrl);

    final isPlaying = isActive && nowPlaying.isPlaying;
    final isBusy = nowPlaying.isBusy;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: InkWell(
                  onTap: onOpen,
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
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkResponse(
                        radius: 28,
                        onTap: isBusy
                            ? null
                            : () async {
                                if (audioUrl.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('home.no_audio'.tr()),
                                    ),
                                  );
                                  return;
                                }

                                if (isActive) {
                                  await notifier.toggle();

                                  ref
                                      .read(analyticsProvider)
                                      .clickObject(
                                        p.id,
                                        meta: {
                                          'screen': 'Home',
                                          'name': p.titulo,
                                          'action': isPlaying
                                              ? 'pause_home'
                                              : 'resume_home',
                                        },
                                      );
                                  return;
                                }

                                await notifier.playFromPlace(p);

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
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Opacity(
                            opacity: isBusy ? 0.65 : 1,
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 28,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.descCorta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
