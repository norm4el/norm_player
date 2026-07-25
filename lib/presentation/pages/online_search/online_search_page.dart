import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // Быстрые варианты популярнейших исполнителей
  final List<String> searchSuggestions = [
    'Littlil',
    'Kizaru',
    'Miyagi',
    'The Weeknd',
    'Radiohead',
    'Ed Sheeran',
    'Taylor Swift',
    'Phonk',
  ];

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleSearch(String query) async {
    final String searchQuery = query.trim().isEmpty ? 'Littlil' : query.trim();
    final Uri url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent("$searchQuery скачать mp3")}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть браузер')),
        );
      }
    }
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Поиск в Гугле 🌐',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Открыть Google',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.language_rounded, color: AppTheme.primaryColor, size: 24),
                      ),
                      onPressed: () => _openGoogleSearch(textEditingController.text),
                    ),
                  ],
                ),
              ),
            ),
            // Поисковая строка Google
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: TextField(
                  controller: textEditingController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  onSubmitted: (value) {
                    _openGoogleSearch(value);
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
                    hintText: 'Искать в Google (например: Littlil)...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15),
                    fillColor: AppTheme.surfaceDark,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (textEditingController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                            onPressed: () {
                              textEditingController.clear();
                              ref.read(onlineSearchProvider.notifier).searchSongs('');
                              setState(() {});
                            },
                          ),
                        IconButton(
                          tooltip: 'Искать в Гугле',
                          icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                          onPressed: () => _openGoogleSearch(textEditingController.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Карточка прямого поиска в Google
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.travel_explore_rounded, size: 28, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Гугл Поиск треков 🌐',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Открывает прямую выдачу Google для загрузки любых файлов.',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () => _openGoogleSearch(textEditingController.text),
                        child: const Text('Гугл 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Популярные исполнители
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'Популярные исполнители:',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: searchSuggestions.map((tag) {
                    final bool isLittlil = tag.toLowerCase() == 'littlil';
                    return ActionChip(
                      backgroundColor: isLittlil ? AppTheme.accentPink.withOpacity(0.2) : AppTheme.surfaceDark,
                      side: BorderSide(color: isLittlil ? AppTheme.accentPink : Colors.white.withOpacity(0.08)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      avatar: Icon(
                        isLittlil ? Icons.star_rounded : Icons.search,
                        size: 16,
                        color: isLittlil ? AppTheme.accentPink : AppTheme.primaryColor,
                      ),
                      label: Text(
                        tag,
                        style: GoogleFonts.inter(
                          color: isLittlil ? AppTheme.accentPink : Colors.white,
                          fontWeight: isLittlil ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () {
                        textEditingController.text = tag;
                        _openGoogleSearch(tag);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            // Дополнительные результаты при поиске
            if (isSearching)
              searchState.when(
                data: (songs) {
                  if (songs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
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
                                child: Container(
                                  width: 48,
                                  height: 48,
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
                              IconButton(
                                icon: const Icon(Icons.language, color: AppTheme.primaryColor),
                                onPressed: () => _openGoogleSearch('${song.title} ${song.artist}'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
