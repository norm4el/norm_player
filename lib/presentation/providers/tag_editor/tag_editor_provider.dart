import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';

class TagOverride {
  final String path;
  final String title;
  final String artist;

  TagOverride({
    required this.path,
    required this.title,
    required this.artist,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'artist': artist,
      };

  factory TagOverride.fromJson(Map<String, dynamic> json) {
    return TagOverride(
      path: json['path'] ?? '',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
    );
  }
}

final tagEditorProvider = StateNotifierProvider<TagEditorNotifier, Map<String, TagOverride>>((ref) {
  return TagEditorNotifier();
});

class TagEditorNotifier extends StateNotifier<Map<String, TagOverride>> {
  static const String _key = 'user_song_tag_overrides_json';

  TagEditorNotifier() : super({}) {
    _loadOverrides();
  }

  void _loadOverrides() {
    try {
      final String? rawJson = SharedPrefImpl.pref.getString(_key);
      if (rawJson != null && rawJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(rawJson);
        final Map<String, TagOverride> map = {};
        decoded.forEach((key, val) {
          map[key] = TagOverride.fromJson(val);
        });
        state = map;
      }
    } catch (_) {}
  }

  void saveTagOverride({required String path, required String title, required String artist}) {
    if (path.isEmpty) return;
    final newMap = Map<String, TagOverride>.from(state);
    newMap[path] = TagOverride(path: path, title: title.trim(), artist: artist.trim());
    state = newMap;
    _save();
  }

  void _save() {
    try {
      final Map<String, dynamic> encodable = {};
      state.forEach((key, val) {
        encodable[key] = val.toJson();
      });
      SharedPrefImpl.pref.setString(_key, jsonEncode(encodable));
    } catch (_) {}
  }
}
