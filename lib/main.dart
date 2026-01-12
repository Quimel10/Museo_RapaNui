import 'dart:io';

import 'package:disfruta_antofagasta/config/constants/enviroment.dart';
import 'package:disfruta_antofagasta/config/router/app_router.dart';
import 'package:disfruta_antofagasta/config/theme/theme_provider.dart';
import 'package:disfruta_antofagasta/shared/session_manager.dart';
import 'package:disfruta_antofagasta/shared/session_flag.dart';
import 'package:disfruta_antofagasta/shared/screens/app_loading_wrapper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// ✅ Android 13+: si no concedes POST_NOTIFICATIONS, no verás el reproductor en notificación.
Future<void> _ensureAndroidNotificationPermission() async {
  if (!Platform.isAndroid) return;

  // permission_handler lo maneja internamente por SDK.
  final status = await Permission.notification.status;
  if (status.isDenied || status.isRestricted || status.isLimited) {
    await Permission.notification.request();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Environment.initEnvironment();

  // ✅ Android 13+ permiso notificaciones
  await _ensureAndroidNotificationPermission();

  // 👇 LEER SESIÓN GUARDADA ANTES DE LEVANTAR LA APP
  final session = await SessionManager.loadSession();
  SessionFlag.hasPersistedSession = session.hasSession;

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('pt'),
        Locale('fr'),
        Locale('it'),
        Locale('ja'),
      ],
      path: 'assets/i18n',
      fallbackLocale: const Locale('es'),
      saveLocale: true,
      child: const ProviderScope(child: MainApp()),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    final appRouter = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: messengerKey,
      routerConfig: appRouter,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      debugShowCheckedModeBanner: false,
      title: 'Museo RapaNui',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      scrollBehavior: NoGlowScrollBehavior(),
      builder: (context, child) {
        return AppLoadingWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
