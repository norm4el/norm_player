import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'music_player_provider.g.dart';

final androidEqualizer = AndroidEqualizer();
final androidLoudnessEnhancer = AndroidLoudnessEnhancer();

// audioPlayer provider
@Riverpod(keepAlive: true)
AudioPlayer musicPlayer(MusicPlayerRef ref) {
  final pipeline = AudioPipeline(
    androidAudioEffects: [
      androidEqualizer,
      androidLoudnessEnhancer,
    ],
  );
  return AudioPlayer(audioPipeline: pipeline);
}
