import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/presentation/providers/current_playing/is_palying.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';
import 'package:norm_player/presentation/providers/favorites/fav_db_music/music_db.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/presentation/providers/search_provider/search.dart';
import 'package:norm_player/presentation/widgets/home_widgets/progress_indicator.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class CurrentPlayingPage extends ConsumerWidget {
  const CurrentPlayingPage({
    super.key,
    this.isPlayingFromFav = false,
    this.isPlayingFromSearch = false,
  });

  final bool isPlayingFromFav;
  final bool isPlayingFromSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isPlaying = ref.watch(isPlayingProvider);
    late List<dynamic> data;
    if (isPlayingFromFav) {
      data = ref.read(musicDbProvider);
    } else if (isPlayingFromSearch) {
      data = ref.read(searchProvider);
    } else {
      data = ref.read(getAllMusicProvider).value!;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white, size: 26),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: ref.watch(musicPlayerProvider).currentIndexStream,
          builder: (context, snapShot) {
            final int index = snapShot.data ?? 0;
            final song = (data.isNotEmpty && index < data.length) ? data[index] : null;
            final title = song?.title ?? 'Unknown Track';
            final artist = song?.artist ?? 'Imported Music';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(height: 10),
                  // Большая квадратная обложка трека в стиле Apple Music / Spotify
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.width * 0.85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.35),
                                AppTheme.surfaceDark,
                                AppTheme.accentColor.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: AppTheme.primaryColor,
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Название трека, исполнитель и кнопка избранного
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppTheme.textSecondary, size: 26),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  // Полоса прогресса
                  const ProgressIndicatingWidget(),
                  // Кнопки управления плеером (Shuffle, Prev, Play/Pause, Next, Repeat)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: AppTheme.textSecondary, size: 22),
                        onPressed: () {
                          ref.read(musicPlayerProvider).setShuffleModeEnabled(true);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
                        onPressed: () {
                          ref.read(musicPlayerProvider).seekToPrevious();
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          if (ref.watch(isPlayingProvider)) {
                            ref.invalidate(isPlayingProvider);
                            ref.read(musicPlayerProvider).pause();
                          } else {
                            ref.invalidate(isPlayingProvider);
                            ref.read(musicPlayerProvider).play();
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceDark,
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.6), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                        onPressed: () {
                          ref.read(musicPlayerProvider).seekToNext();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat, color: AppTheme.textSecondary, size: 22),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Нижняя панель иконок (AirPlay / TV, Очередь, Эквалайзер)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.cast, color: AppTheme.textSecondary, size: 22),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music, color: AppTheme.textSecondary, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: AppTheme.textSecondary, size: 22),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
