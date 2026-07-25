import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/presentation/providers/smart_wave/smart_wave_provider.dart';
import 'package:norm_player/presentation/pages/contact_us/contact_us.dart';
import 'package:norm_player/presentation/providers/current_playing/is_played_once.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/presentation/providers/music/sort_provider.dart';
import 'package:norm_player/presentation/widgets/home_widgets/current_playing_dtls.dart';
import 'package:norm_player/presentation/widgets/home_widgets/play_list_tile_widget.dart';
import 'package:norm_player/utils/theme/app_theme.dart';
import 'package:norm_player/utils/import_helper.dart';

class HomePage extends ConsumerWidget {
  final ScrollController scrollController;

  const HomePage({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Определяем приветствие в зависимости от времени суток
    final int hour = DateTime.now().hour;
    String greeting = 'Добрый вечер 👋';
    if (hour >= 4 && hour < 12) {
      greeting = 'Доброе утро 👋';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Добрый день 👋';
    } else if (hour >= 23 || hour < 4) {
      greeting = 'Доброй ночи 🌙';
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceDark,
      onRefresh: () {
        ref.invalidate(getAllMusicProvider);
        return Future.delayed(const Duration(seconds: 1));
      },
      child: ref.watch(getAllMusicProvider).when(
            data: (data) {
              return CustomScrollView(
                controller: scrollController,
                slivers: [
                  // Заголовок приложения в стиле Screen 1 референса
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: AppTheme.backgroundDark,
                    elevation: 0,
                    pinned: true,
                    toolbarHeight: 70,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'norm',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          greeting,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Мне повезёт 🎲 (Случайная песния)',
                        onPressed: () {
                          final allSongs = ref.read(getAllMusicProvider).valueOrNull ?? [];
                          if (allSongs.isNotEmpty) {
                            final randomSong = allSongs[Random().nextInt(allSongs.length)];
                            ref.read(smartWaveProvider).startSmartWave(randomSong);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎲 Играет случайный трек: ${randomSong.title}'),
                                backgroundColor: AppTheme.surfaceDark,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.casino_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Импорт из файлов (iCloud / Устройство)',
                        onPressed: () => ImportHelper.importAudioFiles(context, ref),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Профиль / Информация',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ContactUsPage()),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  // Блок "Сейчас играет"
                  ref.watch(isPlayedOnceProvider)
                      ? SliverToBoxAdapter(
                          child: InkWell(
                            onTap: () {},
                            child: currentPlayingMusic(data, ref),
                          ),
                        )
                      : const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  // Заголовок "Медиатека" и меню сортировки
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Треки (${data.length})',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          PopupMenuButton<MusicSortOption>(
                            icon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sort_rounded, color: AppTheme.primaryColor, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Сортировка',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            color: AppTheme.surfaceDark,
                            onSelected: (option) {
                              ref.read(musicSortOptionProvider.notifier).state = option;
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: MusicSortOption.dateAdded,
                                child: Text('По дате добавления', style: TextStyle(color: Colors.white)),
                              ),
                              const PopupMenuItem(
                                value: MusicSortOption.titleAsc,
                                child: Text('По названию (А-Я)', style: TextStyle(color: Colors.white)),
                              ),
                              const PopupMenuItem(
                                value: MusicSortOption.artistAsc,
                                child: Text('По исполнителю (А-Я)', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Список треков с учётом выбранной сортировки
                  Builder(builder: (context) {
                    final sortOption = ref.watch(musicSortOptionProvider);
                    final sortedList = List<dynamic>.from(data);
                    if (sortOption == MusicSortOption.titleAsc) {
                      sortedList.sort((a, b) => (a.title ?? '').toString().compareTo((b.title ?? '').toString()));
                    } else if (sortOption == MusicSortOption.artistAsc) {
                      sortedList.sort((a, b) => (a.artist ?? '').toString().compareTo((b.artist ?? '').toString()));
                    }

                    if (sortedList.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.music_off_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'Медиатека пуста',
                                  style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Нажмите иконку облака сверху справа, чтобы добавить музыку из файлов или поискать в интернете',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: sortedList.length,
                        (context, index) {
                          final songItem = sortedList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            child: PlayListTile(
                              isPlayingFromFav: false,
                              artist: songItem.artist ?? 'Unknown Artist',
                              data: songItem.data,
                              title: songItem.title ?? 'Unknown Track',
                              index: index,
                              listOfDatas: sortedList.map((e) => e.data as String).toList(),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
            error: (error, stackTrace) {
              dev.log(error.toString());
              return Center(
                child: Text('Ошибка загрузки медиатеки', style: GoogleFonts.inter(color: Colors.white)),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          ),
    );
  }
}
