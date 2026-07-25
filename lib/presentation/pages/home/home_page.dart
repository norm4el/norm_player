import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/presentation/pages/contact_us/contact_us.dart';
import 'package:norm_player/presentation/providers/current_playing/is_played_once.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
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
                  // Заголовок "Недавно добавленные"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Недавно добавленные',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Все',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Список треков
                  data.isEmpty
                      ? SliverToBoxAdapter(
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
                                    'Нажмите иконку облака сверху справа, чтобы добавить музыку из файлов или iCloud',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            childCount: data.length,
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                child: PlayListTile(
                                  isPlayingFromFav: false,
                                  artist: data[index].artist ?? 'Unknown Artist',
                                  data: data[index].data,
                                  title: data[index].title,
                                  index: index,
                                  listOfDatas: ref
                                      .read(getAllMusicProvider)
                                      .value!
                                      .map((e) => e.data)
                                      .toList(),
                                ),
                              );
                            },
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
            error: (error, stackTrace) {
              log(error.toString());
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
