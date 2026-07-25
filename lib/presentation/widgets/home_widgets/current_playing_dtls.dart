import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/presentation/providers/current_playing/is_palying.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';
import 'package:norm_player/utils/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';

// Виджет карточки "Сейчас играет" для Главного экрана в стиле Screen 1 референса
Widget currentPlayingMusic(List<SongModel> song, WidgetRef ref) {
  return StreamBuilder<int?>(
    stream: ref.watch(musicPlayerProvider).currentIndexStream,
    builder: (context, snapShot) {
      final int index = snapShot.data ?? 0;
      final currentSong = (song.isNotEmpty && index < song.length) ? song[index] : null;
      final title = currentSong?.displayName.split('-').last.trim() ?? 'Unknown Track';
      final artist = currentSong?.artist ?? 'Imported Music';
      final bool isPlaying = ref.watch(isPlayingProvider);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сейчас играет',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Квадратная обложка со скруглением
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.3),
                            AppTheme.accentColor.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Название трека и артист
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist.isEmpty ? 'Imported Music' : artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Круглая кнопка Play/Pause в неоново-синем стиле
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
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.backgroundDark,
                        border: Border.all(color: AppTheme.primaryColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
