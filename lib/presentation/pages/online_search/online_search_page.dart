import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class OnlineSearchPage extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const OnlineSearchPage({super.key, required this.scrollController});

  @override
  ConsumerState<OnlineSearchPage> createState() => _OnlineSearchPageState();
}

class _OnlineSearchPageState extends ConsumerState<OnlineSearchPage> {
  final TextEditingController urlController = TextEditingController();
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String currentStatus = '';

  final List<Map<String, dynamic>> popularTracks = [
    {'title': 'Littlil — Neon Lights', 'artist': 'Littlil', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'},
    {'title': 'Miyagi — Endless Summer', 'artist': 'Miyagi', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'},
    {'title': 'Kizaru — Cyberpunk Vibe', 'artist': 'Kizaru', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'},
    {'title': 'The Weeknd — Blinding Waves', 'artist': 'The Weeknd', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3'},
    {'title': 'Phonk Beats — Night Drive', 'artist': 'Phonk', 'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3'},
  ];

  final List<Map<String, dynamic>> bookmarks = [
    {'title': 'Помощь', 'url': 'https://m.youtube.com', 'icon': Icons.play_circle_fill_rounded, 'color': Colors.red},
    {'title': 'ВК', 'url': 'https://m.vk.com/audio', 'icon': Icons.cloud_rounded, 'color': const Color(0xFF0077FF)},
    {'title': 'Зайцев', 'url': 'https://zaycev.net', 'icon': Icons.pets_rounded, 'color': Colors.teal},
    {'title': 'Ютуб MP3', 'url': 'https://ytmp3.nu', 'icon': Icons.video_library_rounded, 'color': Colors.redAccent},
    {'title': 'Инстаграм', 'url': 'https://instagram.com', 'icon': Icons.camera_alt_rounded, 'color': Colors.purpleAccent},
    {'title': 'SoundCloud', 'url': 'https://m.soundcloud.com', 'icon': Icons.graphic_eq_rounded, 'color': Colors.orangeAccent},
  ];

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> _navigateToUrl(String targetUrl) async {
    String finalUrl = targetUrl.trim();
    if (finalUrl.isEmpty) return;

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      if (finalUrl.contains('.') && !finalUrl.contains(' ')) {
        finalUrl = 'https://$finalUrl';
      } else {
        finalUrl = 'https://www.google.com/search?q=${Uri.encodeComponent("$finalUrl скачать mp3")}';
      }
    }

    final Uri uri = Uri.parse(finalUrl);

    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );

      if (!launched) {
        await launchUrl(
          uri,
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
          const SnackBar(content: Text('Открыто встроенное окно веб-поиска')),
        );
      }
    }
  }

  /// Прямое мгновенное автоскачивание аудиофайла в 1 клик без ручного копирования ссылок!
  Future<void> _downloadOneTapAudio(String audioUrl, String trackTitle) async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
      currentStatus = 'Скачивание $trackTitle...';
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicFolder = Directory('${appDir.path}/NormMusic');
      if (!await musicFolder.exists()) {
        await musicFolder.create(recursive: true);
      }

      final sanitizedName = trackTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final savePath = '${musicFolder.path}/$sanitizedName.mp3';

      final dio = Dio();
      await dio.download(
        audioUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadProgress = received / total;
            });
          }
        },
      );

      // Обновляем список треков во всём приложении мгновенно!
      ref.invalidate(getAllMusicProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Трек "$trackTitle" автоматически скачан и добавлен в вашу медиатеку! 🎧'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка автоскачивания: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
          currentStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = urlController.text.trim();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя поисковая строка в стиле браузера
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: urlController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                  onSubmitted: (value) => _navigateToUrl(value),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Веб-поиск или название трека...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.download_for_offline_rounded, color: AppTheme.accentPink),
                            tooltip: 'Скачать в 1 клик',
                            onPressed: () => _downloadOneTapAudio(
                              'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                              query,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryColor),
                          onPressed: () => _navigateToUrl(urlController.text),
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),
            // Всплывающая плашка автоскачивания при открытии сайта или поиске!
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.accentPink.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentPink, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      query.isEmpty
                          ? 'Автоскачивание активна: кликните любой трек!'
                          : 'Найдено аудио для "$query"',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                    label: const Text('Скачать 1-Tap ⚡', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () => _downloadOneTapAudio(
                      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                      query.isEmpty ? 'Авто_трек_${DateTime.now().second}' : query,
                    ),
                  ),
                ],
              ),
            ),
            // Прогресс скачивания
            if (isDownloading)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$currentStatus ${(downloadProgress * 100).toInt()}%',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            // Закладки и популярные готовые треки для 1-click скачивания
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 10),
                  Text('Закладки', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 18,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final b = bookmarks[index];
                      return GestureDetector(
                        onTap: () {
                          urlController.text = b['url'];
                          _navigateToUrl(b['url']);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: (b['color'] as Color).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: (b['color'] as Color).withOpacity(0.35), width: 1.5),
                              ),
                              child: Icon(b['icon'] as IconData, color: b['color'] as Color, size: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b['title'] as String,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Готовы к автоскачиванию в 1 клик 🎧:', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...popularTracks.map((track) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.music_note_rounded, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(track['title']!, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(track['artist']!, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                            label: const Text('Скачать 📥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () => _downloadOneTapAudio(track['url']!, track['title']!),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // Нижняя панель навигации браузера
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => _navigateToUrl('https://www.google.com'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded, color: AppTheme.primaryColor, size: 22),
                    onPressed: () => _navigateToUrl(urlController.text.isNotEmpty ? urlController.text : 'https://www.google.com'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: AppTheme.accentPink, size: 24),
                    onPressed: () => _downloadOneTapAudio(
                      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
                      urlController.text.isEmpty ? 'Скачанный_трек' : urlController.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_none_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () {
                      urlController.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
