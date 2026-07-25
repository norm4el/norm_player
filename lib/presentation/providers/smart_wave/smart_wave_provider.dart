import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:norm_player/presentation/providers/current_playing/is_palying.dart';
import 'package:norm_player/presentation/providers/current_playing/is_played_once.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:on_audio_query/on_audio_query.dart';

final smartWaveProvider = Provider<SmartWaveService>((ref) {
  return SmartWaveService(ref);
});

class SmartWaveService {
  final Ref ref;

  SmartWaveService(this.ref);

  Future<bool> startSmartWave([SongModel? startingSong]) async {
    final allMusicAsync = ref.read(getAllMusicProvider);
    final allSongs = allMusicAsync.valueOrNull ?? [];
    if (allSongs.isEmpty) return false;

    // Определяем стартовый трек
    final SongModel baseSong = startingSong ?? allSongs[_getRandomIndex(allSongs.length)];

    final String targetArtist = (baseSong.artist ?? '').trim().toLowerCase();
    final String targetAlbum = (baseSong.album ?? '').trim().toLowerCase();

    // Отбираем похожие треки того же исполнителя или альбома
    List<SongModel> matchingSongs = allSongs.where((song) {
      if (song.id == baseSong.id) return false;
      final artist = (song.artist ?? '').trim().toLowerCase();
      final album = (song.album ?? '').trim().toLowerCase();

      bool sameArtist = targetArtist.isNotEmpty && targetArtist != '<unknown>' && artist == targetArtist;
      bool sameAlbum = targetAlbum.isNotEmpty && targetAlbum != '<unknown>' && album == targetAlbum;

      return sameArtist || sameAlbum;
    }).toList();

    // Если похожих мало, дополняем другими треками медиатеки
    if (matchingSongs.length < 5) {
      final remainingSongs = allSongs.where((s) => s.id != baseSong.id && !matchingSongs.contains(s)).toList();
      remainingSongs.shuffle(Random());
      matchingSongs.addAll(remainingSongs);
    } else {
      matchingSongs.shuffle(Random());
    }

    // Составляем итоговую подборку: сначала стартовый трек, затем перемешанные релевантные
    final List<SongModel> smartQueue = [baseSong, ...matchingSongs];
    final List<AudioSource> audioSources = smartQueue.map((s) => AudioSource.file(s.data)).toList();

    final player = ref.read(musicPlayerProvider);
    ref.read(isPlayedOnceProvider.notifier).state = true;
    await player.pause();
    await player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: 0,
    );
    await player.play();
    ref.invalidate(isPlayingProvider);
    return true;
  }

  int _getRandomIndex(int max) => Random().nextInt(max);
}
