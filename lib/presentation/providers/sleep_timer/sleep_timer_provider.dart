import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:norm_player/presentation/providers/current_playing/is_palying.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';

final sleepTimerProvider = StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  return SleepTimerNotifier(ref);
});

class SleepTimerState {
  final int? remainingSeconds;
  final bool isActive;
  final bool untilEndOfTrack;

  SleepTimerState({
    this.remainingSeconds,
    this.isActive = false,
    this.untilEndOfTrack = false,
  });

  SleepTimerState copyWith({
    int? remainingSeconds,
    bool? isActive,
    bool? untilEndOfTrack,
  }) {
    return SleepTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isActive: isActive ?? this.isActive,
      untilEndOfTrack: untilEndOfTrack ?? this.untilEndOfTrack,
    );
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref ref;
  Timer? _timer;

  SleepTimerNotifier(this.ref) : super(SleepTimerState());

  void setTimer(int minutes) {
    cancelTimer();
    final seconds = minutes * 60;
    state = SleepTimerState(remainingSeconds: seconds, isActive: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds == null || state.remainingSeconds! <= 1) {
        _stopPlayback();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds! - 1);
      }
    });
  }

  void setUntilEndOfTrack() {
    cancelTimer();
    state = SleepTimerState(isActive: true, untilEndOfTrack: true);
    
    // Подписываемся на завершение трека
    final player = ref.read(musicPlayerProvider);
    late StreamSubscription sub;
    sub = player.playerStateStream.listen((playerState) {
      if (!state.untilEndOfTrack) {
        sub.cancel();
        return;
      }
      if (playerState.processingState == ProcessingState.completed) {
        _stopPlayback();
        sub.cancel();
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    state = SleepTimerState(isActive: false, remainingSeconds: null, untilEndOfTrack: false);
  }

  void _stopPlayback() {
    cancelTimer();
    ref.read(musicPlayerProvider).pause();
    ref.invalidate(isPlayingProvider);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
