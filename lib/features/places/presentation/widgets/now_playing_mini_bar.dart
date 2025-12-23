import 'package:flutter/material.dart';

/// ⚠️ LEGACY MINI BAR (NO USAR)
/// Esta versión vieja (ValueNotifier) causaba duplicación con el mini real
/// (Riverpod + just_audio) que vive en:
///   lib/shared/audio/now_playing_player.dart  -> NowPlayingMiniBar
///
/// La dejamos para no romper imports/referencias antiguas, pero NO renderiza UI.
/// Si querés mostrar el mini, usá el del router:
///   const NowPlayingMiniBar()  (import desde shared/audio/now_playing_player.dart)

class LegacyNowPlayingMiniBarController {
  static final ValueNotifier<LegacyNowPlayingMiniBarData?> data =
      ValueNotifier<LegacyNowPlayingMiniBarData?>(null);

  static void show(LegacyNowPlayingMiniBarData value) => data.value = value;
  static void hide() => data.value = null;
}

class LegacyNowPlayingMiniBarData {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final bool isPlaying;

  LegacyNowPlayingMiniBarData({
    required this.title,
    this.subtitle,
    this.onTap,
    this.onPlayPause,
    this.isPlaying = true,
  });
}

/// ✅ Widget legacy “apagado” para evitar duplicación.
/// Si algún lugar lo sigue montando, no va a mostrar nada.
class LegacyNowPlayingMiniBar extends StatelessWidget {
  const LegacyNowPlayingMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
