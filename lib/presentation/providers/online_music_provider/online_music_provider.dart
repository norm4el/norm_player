import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viola/data/data_source/online_music/online_music_service.dart';
import 'package:viola/presentation/providers/music/get_all_music.dart';

final onlineSearchProvider = StateNotifierProvider<OnlineSearchNotifier, AsyncValue<List<OnlineSong>>>((ref) {
  return OnlineSearchNotifier(ref);
});

class OnlineSearchNotifier extends StateNotifier<AsyncValue<List<OnlineSong>>> {
  final Ref ref;

  OnlineSearchNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final songs = await OnlineMusicService.searchOnline(query);
      state = AsyncValue.data(songs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> downloadSong(OnlineSong song) async {
    final currentList = state.valueOrNull ?? [];
    final index = currentList.indexWhere((s) => s.id == song.id);
    if (index == -1 || song.isDownloading || song.isDownloaded) return;

    song.isDownloading = true;
    song.downloadProgress = 0.0;
    state = AsyncValue.data(List.from(currentList));

    final success = await OnlineMusicService.downloadSong(
      song: song,
      onProgress: (progress) {
        song.downloadProgress = progress;
        state = AsyncValue.data(List.from(currentList));
      },
    );

    song.isDownloading = false;
    if (success) {
      song.isDownloaded = true;
      // Обновляем общий список локальной музыки в приложении
      ref.invalidate(getAllMusicProvider);
    }
    state = AsyncValue.data(List.from(currentList));
  }
}
