import 'package:disfruta_antofagasta/config/router/app_router_notifier.dart';
import 'package:disfruta_antofagasta/config/router/routes.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/screens/login_screen.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_state.dart';
import 'package:disfruta_antofagasta/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:disfruta_antofagasta/features/home/presentation/screens/home_screen.dart';
import 'package:disfruta_antofagasta/features/map/presentation/screens/map_screen.dart';
import 'package:disfruta_antofagasta/features/places/presentation/screens/place_details_screen.dart';
import 'package:disfruta_antofagasta/features/places/presentation/screens/places_screen.dart';
import 'package:disfruta_antofagasta/shared/widgets/nav_scaffold.dart';
import 'package:disfruta_antofagasta/shared/widgets/splash_gate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final goRouterNotifier = ref.read(goRouterNotifierProvider);

  return GoRouter(
    initialLocation: AppPath.splash,
    debugLogDiagnostics: false,
    refreshListenable: goRouterNotifier,

    routes: [
      GoRoute(
        path: '/login',
        name: AppRoute.login,
        builder: (context, state) {
          return LoginScreen();
        },
      ),
      GoRoute(
        path: '/splash',
        name: AppRoute.splash,
        builder: (context, state) {
          return SplashGate();
        },
      ),
      GoRoute(
        path: '/place/:id',
        name: AppRoute.place,
        builder: (context, state) {
          final placeId = state.pathParameters['id'] ?? 'no-id';
          return PlaceDetailsScreen(placeId: placeId);
        },
      ),
      // Mantiene estado por pestaña con IndexedStack
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            NavScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.home,
                path: AppPath.home,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.places,
                path: AppPath.places,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PlacesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.map,
                path: AppPath.map,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: MapScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.favorites,
                path: AppPath.favorites,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FavoritesScreen()),
              ),
            ],
          ),
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       name: AppRoute.services,
          //       path: AppPath.services,
          //       pageBuilder: (context, state) =>
          //           const NoTransitionPage(child: ServicesScreen()),
          //     ),
          //   ],
          // ),
        ],
      ),
    ],
    redirect: (context, state) {
      final authStatus = goRouterNotifier.authStatus;
      final loggingIn = state.matchedLocation == AppPath.login;
      final onSplash = state.matchedLocation == AppPath.splash;

      if (authStatus == AuthStatus.checking) {
        return onSplash ? null : AppPath.splash;
      }
      if (authStatus == AuthStatus.notAuthenticated) {
        return loggingIn ? null : AppPath.login;
      }

      if (authStatus == AuthStatus.authenticated) {
        // Si ya estás autenticado, evita quedarte en /login o /splash
        if (loggingIn || onSplash) return AppPath.home;
        return null;
      }

      return null;
    },
  );
});
