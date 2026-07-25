import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viola/domain/entity/songs_entity.dart';
import 'package:viola/presentation/providers/favorites/fav_db_music/music_db.dart';
import 'package:viola/presentation/widgets/home_widgets/play_list_tile_widget.dart';
import 'package:viola/utils/theme/app_theme.dart';

class FavoritePage extends ConsumerWidget {
  const FavoritePage({super.key, required this.controller});
  // scrollController for scrollToHide
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<SongsEntity> favSongs = ref.watch(musicDbProvider);
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentPink.withOpacity(0.5)),
              ),
              child: const Icon(Icons.favorite, color: AppTheme.accentPink, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Избранное',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: favSongs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    'У вас пока нет избранных треков.\nНажимайте на сердечко в плеере!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 110, left: 12, right: 12),
              itemCount: favSongs.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: AppTheme.glassDecoration(radius: 16),
                  child: PlayListTile(
                    isPlayingFromFav: true,
                    artist: favSongs[index].artist ?? 'unknown',
                    data: favSongs[index].data,
                    title: favSongs[index].title!,
                    index: index,
                    listOfDatas: ref.read(musicDbProvider).map((e) => e.data).toList(),
                  ),
                );
              },
            ),
    );
  }
}

