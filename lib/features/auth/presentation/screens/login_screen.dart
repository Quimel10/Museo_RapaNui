// lib/ui/auth/login_page.dart
import 'package:animations/animations.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/form/forgot_form.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/form/guest_form.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/form/login_form.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/form/register_form.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/state/auth/auth_provider.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/widgets/auth_tab_bar.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/widgets/glass_card.dart';
import 'package:disfruta_antofagasta/features/auth/presentation/widgets/waves_background.dart';
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const WavesBackground(),
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
                    children: [
                      Image.asset('assets/logo.png', height: 200),
                      const SizedBox(height: 18),
                      ref.watch(forgotModeProvider)
                          ? SizedBox()
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
                            // Límite razonable para la altura animada (ajusta al gusto)
                            final maxH =
                                MediaQuery.of(context).size.height * 0.62;

                            return AnimatedSize(
                              duration: const Duration(
                                milliseconds: 320,
                              ), // 700 es muuuy largo
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              clipBehavior: Clip
                                  .hardEdge, // evita “parpadeos” en los bordes
                              // Le damos un límite de altura para que AnimatedSize pueda interpolar
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  // si el form mide menos, se encoge; si mide más, scrollea
                                  maxHeight: maxH,
                                ),

                                // Permitimos scroll SOLO dentro del área limitada
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
                                        ref.watch(forgotModeProvider)
                                            ? const ForgotForm(
                                                key: ValueKey('forgot'),
                                              )
                                            : const LoginForm(
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
