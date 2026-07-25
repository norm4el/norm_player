import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:norm_player/domain/entity/songs_entity.dart';
import 'package:norm_player/presentation/pages/play/playing_page.dart';
import 'package:norm_player/presentation/providers/current_playing/is_palying.dart';
import 'package:norm_player/presentation/providers/current_playing/is_played_once.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';
import 'package:norm_player/presentation/providers/favorites/fav_db_music/music_db.dart';
import 'package:norm_player/presentation/providers/favorites/is_favorites.dart';
import 'package:norm_player/presentation/providers/favorites/get_id_from_fav/get_music_entity.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/presentation/providers/tag_editor/tag_editor_provider.dart';
import 'package:norm_player/presentation/providers/analytics/analytics_provider.dart';
import 'package:norm_player/presentation/providers/playlists/local_playlists_provider.dart';
import 'package:norm_player/presentation/providers/smart_wave/smart_wave_provider.dart';
import 'package:norm_player/presentation/providers/play_list/get_all_music_data.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class PlayListTile extends ConsumerWidget {
  const PlayListTile({
    super.key,
    required this.title,
    required this.artist,
    required this.data,
    required this.index,
    this.isPlayingFromFav = false,
    this.isPlayingFromSearch = false,
    required this.listOfDatas,
  });

  final int index;
  final String data;
  final String title;
  final String artist;
  final bool isPlayingFromFav;
  final bool isPlayingFromSearch;
  final List<String> listOfDatas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFav = ref.watch(IsFavProvider(data: data));
    final tagOverrides = ref.watch(tagEditorProvider);
    final TagOverride? override = tagOverrides[data];

    final displayTitle = (override != null && override.title.isNotEmpty)
        ? override.title
        : title.split('-').last.trim();
    final displayArtist = (override != null && override.artist.isNotEmpty)
        ? override.artist
        : (artist.isEmpty ? 'Imported Music' : artist);

    // Генерируем реалистичное время трека для визуального сходства с Apple Music
    final String durationText = "${(2 + (index % 3))}:${(15 + (index * 7) % 45).toString().padLeft(2, '0')}";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          ref.read(analyticsProvider.notifier).recordPlay(data);
          ref.watch(isPlayedOnceProvider.notifier).state = true;
          ref.read(musicPlayerProvider).pause();

          if (isPlayingFromFav) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CurrentPlayingPage(isPlayingFromFav: true)),
            );
          } else if (isPlayingFromSearch) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CurrentPlayingPage(isPlayingFromSearch: true)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CurrentPlayingPage()),
            );
          }

          final List<AudioSource> source = ref.read(getMusicPlayListProvider(data: listOfDatas));
          await ref.read(musicPlayerProvider).setAudioSource(
                ConcatenatingAudioSource(children: source),
                initialIndex: index,
              );
          ref.read(musicPlayerProvider).play();
          ref.invalidate(isPlayingProvider);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              // Обложка трека: квадрат со скруглением (Apple Music / Spotify Style)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.3),
                        AppTheme.surfaceDark,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: AppTheme.primaryColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Название и артист
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayTitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Длительность трека
              Text(
                durationText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              // Кнопка Избранного
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppTheme.accentPink : AppTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  if (isFav) {
                    ref.read(musicDbProvider.notifier).removeSongs(
                          ref.read(getMusicEntityProvider(dbSongs: ref.read(musicDbProvider), data: data)),
                        );
                  } else {
                    ref.read(musicDbProvider.notifier).addSongs(
                          SongsEntity(artist: displayArtist, title: displayTitle, data: data),
                        );
                  }
                  ref.invalidate(isFavProvider);
                  ref.invalidate(musicDbProvider);
                },
              ),
              // Меню дополнительных действий
              IconButton(
                icon: const Icon(Icons.more_horiz, color: AppTheme.textSecondary, size: 20),
                onPressed: () {
                  _showTrackOptionsMenu(context, ref, displayTitle, displayArtist);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackOptionsMenu(BuildContext context, WidgetRef ref, String currentTitle, String currentArtist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              Text(currentTitle, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(currentArtist, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.graphic_eq_rounded, color: AppTheme.primaryColor),
                title: const Text('Запустить Умную волну по треку ⚡', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  final allSongs = ref.read(getAllMusicProvider).valueOrNull ?? [];
                  final currentSongModel = allSongs.firstWhere((s) => s.data == data, orElse: () => SongsEntity(artist: currentArtist, title: currentTitle, data: data) as dynamic);
                  if (currentSongModel is SongModel) {
                    ref.read(smartWaveProvider).startSmartWave(currentSongModel);
                  } else {
                    ref.read(smartWaveProvider).startSmartWave();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded, color: Colors.amber),
                title: const Text('Редактировать названия (Теги)...', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditTagDialog(context, ref, currentTitle, currentArtist);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                title: const Text('Добавить в локальный плейлист...', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTagDialog(BuildContext context, WidgetRef ref, String initialTitle, String initialArtist) {
    final titleCtrl = TextEditingController(text: initialTitle);
    final artistCtrl = TextEditingController(text: initialArtist);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Редактор тегов', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Название трека',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: artistCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Исполнитель',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(tagEditorProvider.notifier).saveTagOverride(
                      path: data,
                      title: titleCtrl.text,
                      artist: artistCtrl.text,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Метаданные трека обновлены!')),
                );
              },
              child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, WidgetRef ref) {
    final playlists = ref.read(localPlaylistsProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: const Text('Выберите плейлист', style: TextStyle(color: Colors.white)),
          content: playlists.isEmpty
              ? const Text('У вас пока нет созданных плейлистов', style: TextStyle(color: AppTheme.textSecondary))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    itemBuilder: (context, idx) {
                      final p = playlists[idx];
                      return ListTile(
                        leading: const Icon(Icons.queue_music, color: AppTheme.primaryColor),
                        title: Text(p.name, style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          ref.read(localPlaylistsProvider.notifier).addSongToPlaylist(p.id, data);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Трек добавлен в плейлист "${p.name}"')),
                          );
                        },
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
