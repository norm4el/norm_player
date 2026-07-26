import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';

class LocalPlaylist {
  final String id;
  final String name;
  final List<String> songPaths;
  final DateTime createdAt;

  LocalPlaylist({
    required this.id,
    required this.name,
    required this.songPaths,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songPaths': songPaths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LocalPlaylist.fromJson(Map<String, dynamic> json) {
    return LocalPlaylist(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Без названия',
      songPaths: List<String>.from(json['songPaths'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

final localPlaylistsProvider = StateNotifierProvider<LocalPlaylistsNotifier, List<LocalPlaylist>>((ref) {
  return LocalPlaylistsNotifier();
});

class LocalPlaylistsNotifier extends StateNotifier<List<LocalPlaylist>> {
  static const String _key = 'user_local_playlists_json';

  LocalPlaylistsNotifier() : super([]) {
    _loadPlaylists();
  }

  void _loadPlaylists() {
    try {
      final String? rawJson = SharedPrefImpl.pref.getString(_key);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List decoded = jsonDecode(rawJson);
        state = decoded.map((item) => LocalPlaylist.fromJson(item)).toList();
      } else {
        // Дефолтный плейлист при первом старте
        state = [
          LocalPlaylist(
            id: 'favorite_mix',
            name: 'Любимый микс ⚡',
            songPaths: [],
            createdAt: DateTime.now(),
          )
        ];
        _savePlaylists();
      }
    } catch (_) {
      state = [];
    }
  }

  void _savePlaylists() {
    try {
      final encoded = jsonEncode(state.map((p) => p.toJson()).toList());
      SharedPrefImpl.pref.setString(_key, encoded);
    } catch (_) {}
  }

  void createPlaylist(String name) {
    if (name.trim().isEmpty) return;
    final newPlaylist = LocalPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      songPaths: [],
      createdAt: DateTime.now(),
    );
    state = [...state, newPlaylist];
    _savePlaylists();
  }

  void deletePlaylist(String playlistId) {
    state = state.where((p) => p.id != playlistId).toList();
    _savePlaylists();
  }

  void addSongToPlaylist(String playlistId, String songPath) {
    if (playlistId.isEmpty || songPath.trim().isEmpty) return;
    final targetPath = songPath.trim();
    state = [
      for (final p in state)
        if (p.id == playlistId)
          LocalPlaylist(
            id: p.id,
            name: p.name,
            songPaths: p.songPaths.contains(targetPath)
                ? p.songPaths
                : [...p.songPaths, targetPath],
            createdAt: p.createdAt,
          )
        else
          p
    ];
    _savePlaylists();
  }

  void removeSongFromPlaylist(String playlistId, String songPath) {
    final targetPath = songPath.trim();
    state = [
      for (final p in state)
        if (p.id == playlistId)
          LocalPlaylist(
            id: p.id,
            name: p.name,
            songPaths: p.songPaths.where((path) => path.trim() != targetPath).toList(),
            createdAt: p.createdAt,
          )
        else
          p
    ];
    _savePlaylists();
  }
}
