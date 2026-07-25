import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';

class AnalyticsData {
  final int totalPlays;
  final Map<String, int> songPlayCounts;

  AnalyticsData({
    required this.totalPlays,
    required this.songPlayCounts,
  });

  Map<String, dynamic> toJson() => {
        'totalPlays': totalPlays,
        'songPlayCounts': songPlayCounts,
      };

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      totalPlays: json['totalPlays'] ?? 0,
      songPlayCounts: Map<String, int>.from(json['songPlayCounts'] ?? {}),
    );
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsData>((ref) {
  return AnalyticsNotifier();
});

class AnalyticsNotifier extends StateNotifier<AnalyticsData> {
  static const String _key = 'user_music_analytics_json';

  AnalyticsNotifier() : super(AnalyticsData(totalPlays: 0, songPlayCounts: {})) {
    _load();
  }

  void _load() {
    try {
      final String? rawJson = SharedPrefImpl.pref.getString(_key);
      if (rawJson != null && rawJson.isNotEmpty) {
        state = AnalyticsData.fromJson(jsonDecode(rawJson));
      }
    } catch (_) {}
  }

  void recordPlay(String songPath) {
    if (songPath.isEmpty) return;
    final newCounts = Map<String, int>.from(state.songPlayCounts);
    newCounts[songPath] = (newCounts[songPath] ?? 0) + 1;

    state = AnalyticsData(
      totalPlays: state.totalPlays + 1,
      songPlayCounts: newCounts,
    );

    try {
      SharedPrefImpl.pref.setString(_key, jsonEncode(state.toJson()));
    } catch (_) {}
  }
}
