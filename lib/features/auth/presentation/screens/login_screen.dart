// lib/features/auth/presentation/screens/login_screen.dart
import 'package:animations/animations.dart';
import 'package:disfruta_antofagasta/config/theme/theme_config.dart';

import 'package:disfruta_antofagasta/features/auth/presentation/form/forgot_form.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/form/guest_form.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/form/login_form.dart'
    as login; // 👈 alias, así no hay choque con ForgotForm de ese archivo
import 'package:disfruta_antofagasta/features/auth/presentation/form/register_form.dart';

import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/widgets/auth_tab_bar.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/widgets/glass_card.dart';
// import 'package:disfruta_antofagasta/features/auth/presentation/widgets/waves_background.dart';

import 'package:disfruta_antofagasta/shared/provider/auth_mode_provider.dart';
import 'package:disfruta_antofagasta/shared/provider/forgot_mode_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  AuthMode? _lastMode;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(authModeProvider);

    // Snackbars de error
    ref.listen<int>(authProvider.select((s) => s.errorSeq), (prev, seq) {
      if (prev == seq) return;
      final msg = ref.read(authProvider).errorMessage;
      if (msg.isEmpty) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(msg),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
      });
    });

    final reverse = _lastMode != null ? mode.index < _lastMode!.index : false;
    _lastMode = mode;

    final forgot = ref.watch(forgotModeProvider);

    return Scaffold(
      backgroundColor: AppColors.parchment, // fondo oscuro tipo Louvre
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo negro liso
          Container(color: AppColors.parchment),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),

                      // 🔹 Logo MAPSE Museo Rapa Nui
                      Image.asset(
                        'assets/logo.png', // ya reemplazado por el nuevo
                        height: 110, // antes 200, ahora más elegante
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 32),

                      // Ocultamos las pestañas cuando estamos en modo "olvidé contraseña"
                      forgot
                          ? const SizedBox.shrink()
                          : GlassCard(
                              borderRadius: 24,
                              padding: const EdgeInsets.all(10),
                              child: AuthTabBar(
                                isForgotMode: forgot,
                                value: mode,
                                onChanged: (AuthMode m) =>
                                    ref.read(authModeProvider.notifier).state =
                                        m,
                              ),
                            ),

                      const SizedBox(height: 16),

                      GlassCard(
                        borderRadius: 28,
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxH =
                                MediaQuery.of(context).size.height * 0.62;

                            return AnimatedSize(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              clipBehavior: Clip.hardEdge,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: maxH),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: PageTransitionSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    reverse: reverse,
                                    transitionBuilder:
                                        (child, animation, secondaryAnimation) {
                                          return SharedAxisTransition(
                                            transitionType:
                                                SharedAxisTransitionType
                                                    .horizontal,
                                            animation: animation,
                                            secondaryAnimation:
                                                secondaryAnimation,
                                            fillColor: Colors.transparent,
                                            child: child,
                                          );
                                        },
                                    child: switch (mode) {
                                      AuthMode.login =>
                                        // Alternamos entre Login y Forgot
                                        forgot
                                            ? const ForgotForm(
                                                key: ValueKey('forgot'),
                                              )
                                            : const login.LoginForm(
                                                key: ValueKey('login'),
                                              ),
                                      AuthMode.guest => const GuestForm(
                                        key: ValueKey('guest'),
                                      ),
                                      AuthMode.register => const RegisterForm(
                                        key: ValueKey('register'),
                                      ),
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
