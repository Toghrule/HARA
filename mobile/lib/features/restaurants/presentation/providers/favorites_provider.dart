import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The restaurants the customer marked with a heart, kept on the phone (there are no customer accounts). Nothing about
/// them is sent to the server except the ids asked for when the favourites list is shown.
class FavoritesNotifier extends Notifier<Set<String>> {
  static const _key = 'favorite_restaurants';

  @override
  Set<String> build() {
    _load();

    return const {};
  }

  Future<void> _load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getStringList(_key) ?? const [];
      // A heart given while this was loading is kept.
      state = {...saved, ...state};
    } catch (_) {
      // Starts empty.
    }
  }

  bool isFavorite(String id) => state.contains(id);

  Future<void> toggle(String id) async {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

    try {
      await (await SharedPreferences.getInstance()).setStringList(_key, state.toList());
    } catch (_) {
      // Kept for this run only.
    }
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
