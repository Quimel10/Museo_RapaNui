// lib/shared/widgets/now_playing_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:disfruta_antofagasta/shared/widgets/mini_player.dart';

class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowPlayingProvider);

    if (!now.hasAudio) return const SizedBox.shrink();

    // ✅ Mini player lindo (NO tarjeta gigante con slider)
    return const MiniPlayer();
  }
}
