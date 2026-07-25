import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/data/data_source/online_music/online_music_service.dart';
import 'package:norm_player/presentation/providers/online_music_provider/online_music_provider.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class OnlineSearchPage extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const OnlineSearchPage({super.key, required this.scrollController});

  @override
  ConsumerState<OnlineSearchPage> createState() => _OnlineSearchPageState();
}

class _OnlineSearchPageState extends ConsumerState<OnlineSearchPage> {
  final TextEditingController textEditingController = TextEditingController();

  // Быстрые варианты для нажатия
  final List<String> searchSuggestions = [
    'The Weeknd',
    'Miley Cyrus',
    'Radiohead',
    'Ed Sheeran',
    'Taylor Swift',
    'Daft Punk',
    'Lofi Beats',
    'Phonk',
  ];

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(onlineSearchProvider);
    final isSearching = textEditingController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            // Шапка
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Онлайн-поиск',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            // Поисковая строка
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: TextField(
                  controller: textEditingController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  onSubmitted: (value) {
                    ref.read(onlineSearchProvider.notifier).searchSongs(value);
                    setState(() {});
                  },
                  onChanged: (value) {
                    if (value.length > 2) {
                      ref.read(onlineSearchProvider.notifier).searchSongs(value);
                    } else if (value.isEmpty) {
                      ref.read(onlineSearchProvider.notifier).searchSongs('');
                    }
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Найти трек, исполнителя или альбом...',
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
                              ref.read(onlineSearchProvider.notifier).searchSongs('');
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
            ),
            // Заголовок секции
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  isSearching ? 'Результаты поиска' : 'Рекомендации по поиску',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Содержимое экрана при отсутствии запроса
            if (!isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Информационный блок о живом веб-поиске
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.travel_explore_rounded,
                                size: 36,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Живой поиск музыки',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Вводите название любой песни или артиста в поле выше. Приложение выполнит поиск по онлайн-базам и позволит скачивать любые аудиофайлы прямо в локальную память.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.4,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Популярные запросы:',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: searchSuggestions.map((tag) {
                          return ActionChip(
                            backgroundColor: AppTheme.surfaceDark,
                            side: BorderSide(color: Colors.white.withOpacity(0.08)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            avatar: const Icon(Icons.search, size: 16, color: AppTheme.primaryColor),
                            label: Text(
                              tag,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                            ),
                            onPressed: () {
                              textEditingController.text = tag;
                              ref.read(onlineSearchProvider.notifier).searchSongs(tag);
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              )
            else
              searchState.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text('Треки не найдены в интернете', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: songs.length,
                      (context, index) {
                        final song = songs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${index + 1}',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: song.artworkUrl.isNotEmpty
                                    ? Image.network(
                                        song.artworkUrl,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 52,
                                          height: 52,
                                          color: AppTheme.surfaceDark,
                                          child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
                                        ),
                                      )
                                    : Container(
                                        width: 52,
                                        height: 52,
                                        color: AppTheme.surfaceDark,
                                        child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${song.artist} • ${song.album}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              _buildDownloadButton(song),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                error: (err, st) => SliverToBoxAdapter(
                  child: Center(child: Text('Ошибка: $err', style: const TextStyle(color: Colors.red))),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  ),
                ),
              ),
            // Кнопка "Показать больше ∨" по центру в стиле Screen 3
            if (!isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Показать больше',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(OnlineSong song) {
    if (song.isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text('Скачано', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (song.isDownloading) {
      return SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: song.downloadProgress > 0 ? song.downloadProgress : null,
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
            Text(
              '${(song.downloadProgress * 100).toInt()}%',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return IconButton(
      tooltip: 'Скачать в локальную медиатеку',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.primaryColor, size: 20),
      ),
      onPressed: () {
        ref.read(onlineSearchProvider.notifier).downloadSong(song);
      },
    );
  }
}
