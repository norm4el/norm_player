import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/presentation/providers/search_provider/search.dart';
import 'package:norm_player/presentation/widgets/home_widgets/play_list_tile_widget.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allMusic = ref.watch(getAllMusicProvider).value ?? [];
    final searchResults = ref.watch(searchProvider);
    final isSearching = textEditingController.text.isNotEmpty;
    final displayList = isSearching ? searchResults : allMusic;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            // Шапка в стиле Screen 2 "Библиотека"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Библиотека',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${allMusic.length} трека',
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
            // Поисковая строка в стиле референса (тёмный фон, иконка лупы справа)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: TextField(
                  controller: textEditingController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  onChanged: (value) {
                    ref.read(searchProvider.notifier).searchSongs(search: value);
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Поиск в библиотеке',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15),
                    fillColor: AppTheme.surfaceDark,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5), width: 1),
                    ),
                    suffixIcon: textEditingController.text.isEmpty
                        ? const Icon(Icons.search, color: AppTheme.textSecondary)
                        : IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                            onPressed: () {
                              textEditingController.clear();
                              ref.invalidate(searchProvider);
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
            ),
            // Заголовок "Недавно добавленные"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  isSearching ? 'Результаты поиска' : 'Недавно добавленные',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Список треков
            displayList.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isSearching ? Icons.search_off_rounded : Icons.library_music_outlined,
                              size: 64,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isSearching ? 'Ничего не найдено' : 'Ваша библиотека пуста',
                              style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: displayList.length,
                      (context, index) {
                        final item = displayList[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          child: PlayListTile(
                            isPlayingFromFav: false,
                            isPlayingFromSearch: isSearching,
                            artist: item.artist ?? 'Unknown Artist',
                            data: item.data,
                            title: item.title,
                            index: index,
                            listOfDatas: displayList.map((e) => e.data.toString()).toList(),
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
