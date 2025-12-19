import 'package:flutter/material.dart';

/// Control simple para mostrar/ocultar el mini player sin romper el layout.
/// Más adelante lo conectamos a tu provider/just_audio.
class NowPlayingMiniBarController {
  /// Si es null, el mini player no se muestra.
  static final ValueNotifier<NowPlayingMiniBarData?> data =
      ValueNotifier<NowPlayingMiniBarData?>(null);

  static void show(NowPlayingMiniBarData value) => data.value = value;
  static void hide() => data.value = null;
}

class NowPlayingMiniBarData {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final bool isPlaying;

  NowPlayingMiniBarData({
    required this.title,
    this.subtitle,
    this.onTap,
    this.onPlayPause,
    this.isPlaying = true,
  });
}

class NowPlayingMiniBar extends StatelessWidget {
  const NowPlayingMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<NowPlayingMiniBarData?>(
      valueListenable: NowPlayingMiniBarController.data,
      builder: (context, data, _) {
        if (data == null) return const SizedBox.shrink();

        return SafeArea(
          top: false,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 64,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.white, size: 22),
                  const SizedBox(width: 10),

                  // Texto
                  Expanded(
                    child: InkWell(
                      onTap: data.onTap,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if ((data.subtitle ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              data.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Play/Pause
                  IconButton(
                    onPressed: data.onPlayPause,
                    icon: Icon(
                      data.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),

                  // Close
                  IconButton(
                    onPressed: NowPlayingMiniBarController.hide,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
