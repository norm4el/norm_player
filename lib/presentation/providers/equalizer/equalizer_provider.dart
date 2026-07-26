import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';

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
      _applyToPlayer();
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
    _applyToPlayer();
  }

  void setBass(double val) {
    state = state.copyWith(bassGain: val);
    _save();
    _applyToPlayer();
  }

  void setTreble(double val) {
    state = state.copyWith(trebleGain: val);
    _save();
    _applyToPlayer();
  }

  void _save() {
    try {
      SharedPrefImpl.pref.setString(_presetKey, state.preset.name);
      SharedPrefImpl.pref.setDouble(_bassKey, state.bassGain);
      SharedPrefImpl.pref.setDouble(_trebleKey, state.trebleGain);
    } catch (_) {}
  }

  Future<void> _applyToPlayer() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (!androidEqualizer.enabled) {
        await androidEqualizer.setEnabled(true);
      }
      if (!androidLoudnessEnhancer.enabled) {
        await androidLoudnessEnhancer.setEnabled(true);
      }

      // LoudnessEnhancer target gain in millibels. bassGain (0.0 to 1.0) -> max 2000 mB
      final bassGainMB = ((state.bassGain - 0.5) * 4000).clamp(-2000, 2000);
      await androidLoudnessEnhancer.setTargetGain(bassGainMB / 1000.0);

      // We could use Equalizer bands here if we want more granular control,
      // but LoudnessEnhancer works great for simple Bass/Volume boost.
    } catch (e) {
      debugPrint('Equalizer error: $e');
    }
  }
}
