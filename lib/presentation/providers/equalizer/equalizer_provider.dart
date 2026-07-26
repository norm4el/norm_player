import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';

enum EqualizerPreset { normal, bassBoost, rock, electronic, vocal }

class EqualizerSettings {
  final EqualizerPreset preset;
  final double bassGain; // 0.0 to 1.0
  final double trebleGain; // 0.0 to 1.0

  EqualizerSettings({
    required this.preset,
    required this.bassGain,
    required this.trebleGain,
  });

  EqualizerSettings copyWith({
    EqualizerPreset? preset,
    double? bassGain,
    double? trebleGain,
  }) {
    return EqualizerSettings(
      preset: preset ?? this.preset,
      bassGain: bassGain ?? this.bassGain,
      trebleGain: trebleGain ?? this.trebleGain,
    );
  }
}

final equalizerProvider = StateNotifierProvider<EqualizerNotifier, EqualizerSettings>((ref) {
  return EqualizerNotifier();
});

class EqualizerNotifier extends StateNotifier<EqualizerSettings> {
  static const String _presetKey = 'user_eq_preset';
  static const String _bassKey = 'user_eq_bass';
  static const String _trebleKey = 'user_eq_treble';

  EqualizerNotifier()
      : super(EqualizerSettings(
          preset: EqualizerPreset.normal,
          bassGain: 0.5,
          trebleGain: 0.5,
        )) {
    _load();
  }

  void _load() {
    try {
      final String? pStr = SharedPrefImpl.pref.getString(_presetKey);
      final double? bass = SharedPrefImpl.pref.getDouble(_bassKey);
      final double? treble = SharedPrefImpl.pref.getDouble(_trebleKey);

      EqualizerPreset preset = EqualizerPreset.normal;
      if (pStr != null) {
        preset = EqualizerPreset.values.firstWhere((e) => e.name == pStr, orElse: () => EqualizerPreset.normal);
      }

      state = EqualizerSettings(
        preset: preset,
        bassGain: bass ?? 0.5,
        trebleGain: treble ?? 0.5,
      );
    } catch (_) {}
  }

  void setPreset(EqualizerPreset preset) {
    double bass = 0.5;
    double treble = 0.5;

    switch (preset) {
      case EqualizerPreset.bassBoost:
        bass = 0.9;
        treble = 0.6;
        break;
      case EqualizerPreset.rock:
        bass = 0.7;
        treble = 0.8;
        break;
      case EqualizerPreset.electronic:
        bass = 0.85;
        treble = 0.85;
        break;
      case EqualizerPreset.vocal:
        bass = 0.3;
        treble = 0.9;
        break;
      case EqualizerPreset.normal:
        bass = 0.5;
        treble = 0.5;
        break;
    }

    state = state.copyWith(preset: preset, bassGain: bass, trebleGain: treble);
    _save();
  }

  void setBass(double val) {
    state = state.copyWith(bassGain: val);
    _save();
  }

  void setTreble(double val) {
    state = state.copyWith(trebleGain: val);
    _save();
  }

  void _save() {
    try {
      SharedPrefImpl.pref.setString(_presetKey, state.preset.name);
      SharedPrefImpl.pref.setDouble(_bassKey, state.bassGain);
      SharedPrefImpl.pref.setDouble(_trebleKey, state.trebleGain);
    } catch (_) {}
  }
}
