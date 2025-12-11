import 'package:disfruta_antofagasta/features/places/presentation/widgets/audio_player_widget.dart';
import 'package:disfruta_antofagasta/shared/provider/now_playing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowPlayingProvider);

    if (!now.hasAudio) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        // un poco por encima de la bottom-nav
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        child: Material(
          color: Colors.black.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        now.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        ref.read(nowPlayingProvider.notifier).clear();
                      },
                    ),
                  ],
                ),
                if (now.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    now.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Tu reproductor real
                if (now.url != null) AudioPlayerWidget(url: now.url!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
