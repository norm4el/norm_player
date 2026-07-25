import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/domain/entity/songs_entity.dart';
import 'package:norm_player/presentation/providers/favorites/fav_db_music/music_db.dart';
import 'package:norm_player/presentation/widgets/home_widgets/play_list_tile_widget.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class FavoritePage extends ConsumerWidget {
  const FavoritePage({super.key, required this.controller});
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<SongsEntity> favSongs = ref.watch(musicDbProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Избранное',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${favSongs.length} трека',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            favSongs.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'В избранном пока пусто',
                              style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Нажимайте на сердечко при прослушивании треков, чтобы они появились здесь',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: favSongs.length,
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          child: PlayListTile(
                            isPlayingFromFav: true,
                            artist: favSongs[index].artist ?? 'Unknown Artist',
                            data: favSongs[index].data,
                            title: favSongs[index].title!,
                            index: index,
                            listOfDatas: ref.read(musicDbProvider).map((e) => e.data).toList(),
                          ),
                        );
                      },
                    ),
                  ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
