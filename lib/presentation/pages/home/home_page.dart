import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viola/presentation/pages/contact_us/contact_us.dart';
import 'package:viola/presentation/providers/current_playing/is_played_once.dart';
import 'package:viola/presentation/providers/music/get_all_music.dart';
import 'package:viola/presentation/widgets/home_widgets/buttons_home_song_controllers/play_and_pause.dart';
import 'package:viola/presentation/widgets/home_widgets/buttons_home_song_controllers/skip_next.dart';
import 'package:viola/presentation/widgets/home_widgets/buttons_home_song_controllers/skip_previos.dart';
import 'package:viola/presentation/widgets/home_widgets/current_playing_dtls.dart';
import 'package:viola/presentation/widgets/home_widgets/play_list_tile_widget.dart';
import 'package:viola/utils/dynamic_sizes/dynamic_sizes.dart';
import 'package:viola/utils/theme/app_theme.dart';
import 'package:viola/utils/import_helper.dart';

class HomePage extends ConsumerWidget {
  final ScrollController scrollController;

  const HomePage({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  // title app bar
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    backgroundColor: AppTheme.backgroundDark,
                    elevation: 0,
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.accentCyan],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Viola Music',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1),
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
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: const Icon(
                            Icons.add_to_photos,
                            color: AppTheme.accentCyan,
                            size: 20,
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ContactUsPage()));
                          },
                          icon: const Icon(
                            Icons.info_outline,
                            color: AppTheme.textSecondary,
                            size: 24,
                          )),
                      const SizedBox(width: 8),
                    ],
                  ),
                  // topside section which contain data of current playing music
                  ref.watch(isPlayedOnceProvider)
                      ? SliverToBoxAdapter(
                          child: InkWell(
                              onTap: () {},
                              child: currentPlayingMusic(data, ref)),
                        )
                      : const SliverToBoxAdapter(),
                  // music controlls section
                  ref.watch(isPlayedOnceProvider)
                      ? SliverAppBar(
                          automaticallyImplyLeading: false,
                          pinned: true,
                          backgroundColor: AppTheme.surfaceDark.withOpacity(0.9),
                          toolbarHeight: context.screenHeight(50),
                          title: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                skipPreviosButton(ref),
                                pauseAndPlayButton(ref),
                                skipNextButton(ref)
                              ],
                            ),
                          ),
                          bottom: const PreferredSize(
                              preferredSize: Size(100, 15), child: SizedBox()),
                        )
                      : const SliverToBoxAdapter(),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: data.length,
                      (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: AppTheme.glassDecoration(radius: 16),
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
                  )
                ],
              );
            },
            error: (error, stackTrace) {
              log(error.toString());
              return const Center(
                child: Text('Sorry No Songs found'),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
          ),
    );
  }
}
