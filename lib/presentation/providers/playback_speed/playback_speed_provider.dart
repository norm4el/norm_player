import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';

final playbackSpeedProvider = StateNotifierProvider<PlaybackSpeedNotifier, double>((ref) {
  return PlaybackSpeedNotifier(ref);
});

class PlaybackSpeedNotifier extends StateNotifier<double> {
  final Ref ref;

  PlaybackSpeedNotifier(this.ref) : super(1.0);

  void setSpeed(double speed) {
    state = speed;
    ref.read(musicPlayerProvider).setSpeed(speed);
  }
}
