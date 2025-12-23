// lib/config/router/app_router.dart
import 'package:disfruta_antofagasta/config/router/app_router_notifier.dart';
import 'package:disfruta_antofagasta/config/router/routes.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/screens/login_screen.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_state.dart';
import 'package:disfruta_antofagasta/features/home/presentation/screens/home_screen.dart';
import 'package:disfruta_antofagasta/features/places/presentation/screens/place_details_screen.dart';
import 'package:disfruta_antofagasta/features/places/presentation/screens/places_screen.dart';
import 'package:disfruta_antofagasta/features/scan/presentation/screens/qr_scanner_screen.dart';
import 'package:disfruta_antofagasta/shared/audio/now_playing_player.dart';
import 'package:disfruta_antofagasta/shared/session_flag.dart';
import 'package:disfruta_antofagasta/shared/widgets/nav_scaffold.dart';
import 'package:disfruta_antofagasta/shared/widgets/splash_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final goRouterNotifier = ref.read(goRouterNotifierProvider);

  final hasPersistedSession = SessionFlag.hasPersistedSession;
  final initialLocation = hasPersistedSession ? AppPath.home : AppPath.splash;

  return GoRouter(
    initialLocation: initialLocation,
    debugLogDiagnostics: false,
    refreshListenable: goRouterNotifier,

    routes: [
      // LOGIN
      GoRoute(
        path: AppPath.login,
        name: AppRoute.login,
        builder: (context, state) => LoginScreen(),
      ),

      // SPLASH
      GoRoute(
        path: AppPath.splash,
        name: AppRoute.splash,
        builder: (context, state) => SplashGate(),
      ),

      // ============================
      //  SHELL CON BOTTOM NAV + MINI PLAYER
      // ============================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Stack(
            children: [
              NavScaffold(navigationShell: navigationShell),
              const NowPlayingMiniBar(),
            ],
          );
        },
        branches: [
          // 0 - ESCANEAR QR
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: QrScannerScreen()),
              ),
            ],
          ),

          // 1 - INICIO
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.home,
                path: AppPath.home, // "/"
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
                routes: [
                  // ✅ Detalle dentro del TAB INICIO (mantiene menú)
                  GoRoute(
                    path: 'place/:id', // => "/place/:id"
                    name: 'home_place',
                    builder: (context, state) {
                      final placeId = state.pathParameters['id'] ?? 'no-id';
                      return PlaceDetailsScreen(placeId: placeId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // 2 - PIEZAS / BUSCAR
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.places,
                path: AppPath.places, // "/places"
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PlacesScreen()),
                routes: [
                  // ✅ Detalle dentro del TAB PIEZAS (mantiene menú)
                  GoRoute(
                    path: 'place/:id', // => "/places/place/:id"
                    name: 'places_place',
                    builder: (context, state) {
                      final placeId = state.pathParameters['id'] ?? 'no-id';
                      return PlaceDetailsScreen(placeId: placeId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],

    // ============================
    // REDIRECTS POR AUTH
    // ============================
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == AppPath.login;
      final onSplash = state.matchedLocation == AppPath.splash;

      final authStatus = goRouterNotifier.authStatus;

      // 1) Si HAY sesión persistida
      if (SessionFlag.hasPersistedSession) {
        if (loggingIn || onSplash) return AppPath.home;
        return null;
      }

      // 2) Si NO hay sesión persistida
      if (authStatus == AuthStatus.checking) {
        return onSplash ? null : AppPath.splash;
      }

      if (authStatus == AuthStatus.notAuthenticated) {
        return loggingIn ? null : AppPath.login;
      }

      if (authStatus == AuthStatus.authenticated) {
        if (loggingIn || onSplash) return AppPath.home;
        return null;
      }

      return null;
    },
  );
});
