import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';

class HistoryItem {
  final String title;
  final String artist;
  final String path;
  final DateTime playedAt;

  HistoryItem({
    required this.title,
    required this.artist,
    required this.path,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'path': path,
        'playedAt': playedAt.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      title: json['title'] ?? 'Unknown Track',
      artist: json['artist'] ?? 'Unknown Artist',
      path: json['path'] ?? '',
      playedAt: json['playedAt'] != null
          ? DateTime.tryParse(json['playedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<HistoryItem>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<List<HistoryItem>> {
  static const String _key = 'user_music_history_json';

  HistoryNotifier() : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    try {
      final String? rawJson = SharedPrefImpl.pref.getString(_key);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List decoded = jsonDecode(rawJson);
        state = decoded.map((item) => HistoryItem.fromJson(item)).toList();
      }
    } catch (_) {}
  }

  void addTrack({required String title, required String artist, required String path}) {
    if (path.isEmpty) return;

    final newItem = HistoryItem(
      title: title,
      artist: artist,
      path: path,
      playedAt: DateTime.now(),
    );

    // Удаляем предыдущие вхождения этого же файла
    final filtered = state.where((item) => item.path != path).toList();
    // Добавляем в начало и ограничиваем 50 треками
    state = [newItem, ...filtered].take(50).toList();

    try {
      final encoded = jsonEncode(state.map((item) => item.toJson()).toList());
      SharedPrefImpl.pref.setString(_key, encoded);
    } catch (_) {}
  }

  void clearHistory() {
    state = [];
    SharedPrefImpl.pref.remove(_key);
  }
}
