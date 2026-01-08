import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/app_bootstrap_provider.dart';

class AppLoadingWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLoadingWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLoadingWrapper> createState() => _AppLoadingWrapperState();
}

class _AppLoadingWrapperState extends ConsumerState<AppLoadingWrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(appBootstrapProvider.notifier).runBootstrap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boot = ref.watch(appBootstrapProvider);

    return Stack(
      children: [
        widget.child,

        if (boot.isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none, // ✅ SIN underline
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
