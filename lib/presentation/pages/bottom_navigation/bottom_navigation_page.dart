import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:norm_player/presentation/pages/favorite/favorites_page.dart';
import 'package:norm_player/presentation/pages/home/home_page.dart';
import 'package:norm_player/presentation/pages/playlists/playlists_page.dart';
import 'package:norm_player/presentation/pages/search/search_page.dart';
import 'package:norm_player/presentation/pages/online_search/online_search_page.dart';
import 'package:norm_player/presentation/pages/play/playing_page.dart';
import 'package:norm_player/presentation/providers/current_playing/is_palying.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/presentation/widgets/visualizer/neon_waveform_widget.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class MusicBottomSheet extends ConsumerStatefulWidget {
  const MusicBottomSheet({super.key});

  @override
  ConsumerState<MusicBottomSheet> createState() => _MusicBottomSheetState();
}

class _MusicBottomSheetState extends ConsumerState<MusicBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      HomePage(scrollController: _scrollController),
      SearchPage(scrollController: _scrollController),
      OnlineSearchPage(scrollController: _scrollController),
      PlaylistsPage(controller: _scrollController),
      FavoritePage(controller: _scrollController),
    ];

    final songs = ref.watch(getAllMusicProvider).valueOrNull ?? [];
    final bool isPlaying = ref.watch(isPlayingProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          pages[currentIndex],
          // Нижняя всплывающая интерактивная плашка играющего трека (Floating Mini-Player)
          Positioned(
            left: 12,
            right: 12,
            bottom: 6,
            child: StreamBuilder<int?>(
              stream: ref.watch(musicPlayerProvider).currentIndexStream,
              builder: (context, snapshot) {
                final int idx = snapshot.data ?? 0;
                if (songs.isEmpty || idx >= songs.length) {
                  return const SizedBox.shrink();
                }
                final currentSong = songs[idx];
                final title = currentSong.displayName.split('-').last.trim();
                final artist = currentSong.artist ?? 'Norm Music';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.bottomToTop,
                        child: const CurrentPlayingPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.music_note_rounded, color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      artist,
                                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isPlaying) ...[
                                    const SizedBox(width: 6),
                                    const NeonWaveformWidget(height: 12, barCount: 5),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppTheme.primaryColor, size: 36),
                          onPressed: () {
                            if (isPlaying) {
                              ref.read(musicPlayerProvider).pause();
                            } else {
                              ref.read(musicPlayerProvider).play();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                          onPressed: () {
                            ref.read(musicPlayerProvider).seekToNext();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, Icons.home_outlined),
                _buildNavItem(1, Icons.search_rounded, Icons.search),
                _buildNavItem(2, Icons.cloud_download_rounded, Icons.cloud_download_outlined),
                _buildNavItem(3, Icons.queue_music_rounded, Icons.queue_music_outlined),
                _buildNavItem(4, Icons.favorite, Icons.favorite_border),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}
