import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>((
  ref,
) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorites') ?? [];
    state = ids.map(int.parse).toSet();
  }

  Future<void> toggle(int placeId) async {
    final newState = {...state};
    if (newState.contains(placeId)) {
      newState.remove(placeId);
    } else {
      newState.add(placeId);
    }
    state = newState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorites',
      state.map((e) => e.toString()).toList(),
    );
  }

  bool isFavorite(int id) => state.contains(id);
}
