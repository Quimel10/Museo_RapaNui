import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:disfruta_antofagasta/features/home/domain/entities/place.dart';
import 'package:disfruta_antofagasta/shared/audio/audio_player_service.dart';

class NowPlayingState {
  final String? url;
  final String title;
  final String subtitle;
  final int? placeId;
  final bool isPlaying;

  /// ✅ NUEVO: portada y descripción para cuando NO tenemos PlaceEntity
  final String? imageUrl;
  final String? descriptionHtml;

  /// Si existe, seguimos guardando PlaceEntity (flujo Home)
  final PlaceEntity? place;

  const NowPlayingState({
    this.url,
    this.title = '',
    this.subtitle = '',
    this.placeId,
    this.isPlaying = false,
    this.imageUrl,
    this.descriptionHtml,
    this.place,
  });

  bool get hasAudio => url != null && url!.isNotEmpty;

  NowPlayingState copyWith({
    String? url,
    String? title,
    String? subtitle,
    int? placeId,
    bool? isPlaying,
    String? imageUrl,
    String? descriptionHtml,
    PlaceEntity? place,
  }) {
    return NowPlayingState(
      url: url ?? this.url,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      placeId: placeId ?? this.placeId,
      isPlaying: isPlaying ?? this.isPlaying,
      imageUrl: imageUrl ?? this.imageUrl,
      descriptionHtml: descriptionHtml ?? this.descriptionHtml,
      place: place ?? this.place,
    );
  }
}

class NowPlayingNotifier extends StateNotifier<NowPlayingState> {
  NowPlayingNotifier(this._audio) : super(const NowPlayingState());

  final AudioPlayerService _audio;

  /// 🎧 MÉTODO CENTRAL
  /// Reproduce una pieza y REEMPLAZA cualquier audio anterior
  Future<void> playFromPlace(PlaceEntity place) async {
    if (place.audio.isEmpty) return;

    await _audio.stop();

    // 👇 si tenemos PlaceEntity, también guardamos cover fallback por las dudas
    final cover = place.imagenHigh.isNotEmpty ? place.imagenHigh : '';

    state = NowPlayingState(
      url: place.audio,
      title: place.titulo,
      subtitle: place.descCorta,
      placeId: place.id,
      place: place,
      isPlaying: true,
      imageUrl: cover.isNotEmpty ? cover : null,
      descriptionHtml:
          null, // si tu PlaceEntity tuviera html largo, acá lo setearías
    );

    await _audio.playOrResume(place.audio);
  }

  /// 🎧 Reproduce por URL (detalle u otros contextos)
  Future<void> playFromUrl({
    required String url,
    required String title,
    String subtitle = '',
    int? placeId,
    PlaceEntity? place,

    /// ✅ NUEVO
    String? imageUrl,
    String? descriptionHtml,
  }) async {
    if (url.trim().isEmpty) return;

    await _audio.stop();

    // Si viene place, priorizamos su imagenHigh
    final coverFromPlace = (place != null && place.imagenHigh.isNotEmpty)
        ? place.imagenHigh
        : null;

    state = NowPlayingState(
      url: url,
      title: title,
      subtitle: subtitle,
      placeId: placeId,
      place: place,
      isPlaying: true,
      imageUrl:
          coverFromPlace ??
          (imageUrl?.trim().isNotEmpty == true ? imageUrl!.trim() : null),
      descriptionHtml: (descriptionHtml?.trim().isNotEmpty == true)
          ? descriptionHtml!.trim()
          : null,
    );

    await _audio.playOrResume(url);
  }

  Future<void> pause() async {
    await _audio.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> resume() async {
    final url = state.url;
    if (url == null || url.isEmpty) return;

    await _audio.playOrResume(url);
    state = state.copyWith(isPlaying: true);
  }

  Future<void> toggle() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> clear() async {
    await _audio.stop();
    state = const NowPlayingState();
  }
}

final nowPlayingProvider =
    StateNotifierProvider<NowPlayingNotifier, NowPlayingState>((ref) {
      final audio = ref.read(audioPlayerProvider);
      return NowPlayingNotifier(audio);
    });
