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

  /// Открытие встроенного окна браузера прямо внутри приложения без перехода в сторонние программы
  Future<void> _openInAppGoogleSearch(String query) async {
    final String searchQuery = query.trim().isEmpty ? 'Littlil' : query.trim();
    final Uri url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent("$searchQuery скачать mp3")}');

    try {
      // Использование LaunchMode.inAppBrowserView / inAppWebView заставляет платформу открывать окно прямо в приложении
      bool launched = false;
      try {
        launched = await launchUrl(
          url,
          mode: LaunchMode.inAppBrowserView,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        await launchUrl(
          url,
          mode: LaunchMode.inAppWebView,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка открытия встроенного окна поиска'),
            backgroundColor: AppTheme.surfaceDark,
          ),
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
            // Заголовок
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Поиск в приложения 🌐',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Встроенный Google окно',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.open_in_browser_rounded, color: AppTheme.primaryColor, size: 24),
                      ),
                      onPressed: () => _openInAppGoogleSearch(textEditingController.text),
                    ),
                  ],
                ),
              ),
            ),
            // Поисковое окно прямо в приложении
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: textEditingController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  onSubmitted: (value) {
                    ref.read(onlineSearchProvider.notifier).searchSongs(value);
                    _openInAppGoogleSearch(value);
                  },
                  onChanged: (value) {
                    if (value.length > 1) {
                      ref.read(onlineSearchProvider.notifier).searchSongs(value);
                    } else if (value.isEmpty) {
                      ref.read(onlineSearchProvider.notifier).searchSongs('');
                    }
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Введите название или исполнителя (например: Littlil)...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
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
                          tooltip: 'Открыть окно поиска',
                          icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                          onPressed: () {
                            ref.read(onlineSearchProvider.notifier).searchSongs(textEditingController.text);
                            _openInAppGoogleSearch(textEditingController.text);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Внутренняя карточка встроенного окна Google
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.window_rounded, size: 24, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Окно онлайн-поиска Google 🌐',
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Работает прямо внутри приложения в оверлейном окне.',
                                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.travel_explore_rounded, color: Colors.white),
                          label: const Text(
                            'Открыть встроенный веб-поиск 🚀',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () => _openInAppGoogleSearch(textEditingController.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Секция чипсов
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text(
                  'Быстрый поиск артистов:',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        ref.read(onlineSearchProvider.notifier).searchSongs(tag);
                        _openInAppGoogleSearch(tag);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            // Результаты прямого поиска треков внутри приложения
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  isSearching ? 'Прямой список аудиорезультатов:' : 'Популярные аудиозаписи в сети:',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            searchState.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Нажмите «Открыть встроенный веб-поиск», чтобы найти любой файл.', style: TextStyle(color: AppTheme.textSecondary)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.music_note, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(song.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${song.artist} • ${song.album}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Открыть встроенное окно',
                                icon: const Icon(Icons.search, color: AppTheme.primaryColor),
                                onPressed: () => _openInAppGoogleSearch('${song.title} ${song.artist}'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
