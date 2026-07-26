import 'package:flutter_riverpod/flutter_riverpod.dart';

class AbLoopState {
  final Duration? pointA;
  final Duration? pointB;
  final bool isLooping;

  AbLoopState({
    this.pointA,
    this.pointB,
    this.isLooping = false,
  });

  AbLoopState copyWith({
    Duration? pointA,
    Duration? pointB,
    bool? isLooping,
  }) {
    return AbLoopState(
      pointA: pointA ?? this.pointA,
      pointB: pointB ?? this.pointB,
      isLooping: isLooping ?? this.isLooping,
    );
  }
}

final abLoopProvider = StateNotifierProvider<AbLoopNotifier, AbLoopState>((ref) {
  return AbLoopNotifier();
});

class AbLoopNotifier extends StateNotifier<AbLoopState> {
  AbLoopNotifier() : super(AbLoopState());

  void setPointA(Duration currentPosition) {
    state = state.copyWith(pointA: currentPosition);
  }

  void setPointB(Duration currentPosition) {
    if (state.pointA != null && currentPosition > state.pointA!) {
      state = state.copyWith(pointB: currentPosition, isLooping: true);
    }
  }

  void resetLoop() {
    state = AbLoopState();
  }
}
