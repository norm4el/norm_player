import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, Map<String, int>>((ref) {
  return BookmarksNotifier();
});

class BookmarksNotifier extends StateNotifier<Map<String, int>> {
  static const String _key = 'user_song_bookmarks_json';

  BookmarksNotifier() : super({}) {
    _load();
  }

  void _load() {
    try {
      final String? rawJson = SharedPrefImpl.pref.getString(_key);
      if (rawJson != null && rawJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(rawJson);
        state = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
    } catch (_) {}
  }

  void savePosition(String path, int positionMs) {
    if (path.isEmpty || positionMs < 5000) return; // Игнорируем совсем короткие прослушивания
    final newMap = Map<String, int>.from(state);
    newMap[path] = positionMs;
    state = newMap;
    try {
      SharedPrefImpl.pref.setString(_key, jsonEncode(state));
    } catch (_) {}
  }

  int getSavedPosition(String path) {
    return state[path] ?? 0;
  }
}
