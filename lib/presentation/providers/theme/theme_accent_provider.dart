import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';

final themeAccentProvider = StateNotifierProvider<ThemeAccentNotifier, Color>((ref) {
  return ThemeAccentNotifier();
});

class ThemeAccentNotifier extends StateNotifier<Color> {
  static const String _key = 'user_theme_accent_color_int';

  static const Color electricBlue = Color(0xFF3D7EFF);
  static const Color cyberpunkPink = Color(0xFFFF2E93);
  static const Color emeraldGreen = Color(0xFF00E676);
  static const Color sunsetGold = Color(0xFFFFB300);

  ThemeAccentNotifier() : super(electricBlue) {
    _load();
  }

  void _load() {
    try {
      final int? savedColorValue = SharedPrefImpl.pref.getInt(_key);
      if (savedColorValue != null) {
        state = Color(savedColorValue);
      }
    } catch (_) {}
  }

  void setAccentColor(Color color) {
    state = color;
    try {
      SharedPrefImpl.pref.setInt(_key, color.value);
    } catch (_) {}
  }
}
