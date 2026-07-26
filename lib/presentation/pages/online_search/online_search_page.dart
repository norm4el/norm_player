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

  // Закладки точь-в-точь как на скриншоте пользователя
  final List<Map<String, dynamic>> bookmarks = [
    {
      'title': 'Помощь',
      'url': 'https://m.youtube.com',
      'icon': Icons.play_circle_fill_rounded,
      'color': Colors.red,
    },
    {
      'title': 'ВК',
      'url': 'https://m.vk.com/audio',
      'icon': Icons.cloud_rounded,
      'color': const Color(0xFF0077FF),
    },
    {
      'title': 'Зайцев',
      'url': 'https://zaycev.net',
      'icon': Icons.pets_rounded,
      'color': Colors.teal,
    },
    {
      'title': 'Ютуб MP3',
      'url': 'https://ytmp3.nu',
      'icon': Icons.video_library_rounded,
      'color': Colors.redAccent,
    },
    {
      'title': 'Инстаграм',
      'url': 'https://instagram.com',
      'icon': Icons.camera_alt_rounded,
      'color': Colors.purpleAccent,
    },
    {
      'title': 'SoundCloud',
      'url': 'https://m.soundcloud.com',
      'icon': Icons.graphic_eq_rounded,
      'color': Colors.orangeAccent,
    },
  ];

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  /// Открытие встроенного веб-браузера прямо внутри приложения
  Future<void> _navigateToUrl(String targetUrl) async {
    String finalUrl = targetUrl.trim();
    if (finalUrl.isEmpty) return;

    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      if (finalUrl.contains('.') && !finalUrl.contains(' ')) {
        finalUrl = 'https://$finalUrl';
      } else {
        finalUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(finalUrl + " скачать mp3")}';
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
          const SnackBar(content: Text('Не удалось открыть ссылку во встроенном веб-окне')),
        );
      }
    }
  }

  /// Прямое скачивание аудиофайла по URL со страницы любого сайта в медиатеку приложения
  Future<void> _downloadAudioFile(String directAudioUrl, String trackName) async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
      currentStatus = 'Загрузка $trackName...';
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final musicFolder = Directory('${appDir.path}/NormMusic');
      if (!await musicFolder.exists()) {
        await musicFolder.create(recursive: true);
      }

      final sanitizedName = trackName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final savePath = '${musicFolder.path}/$sanitizedName.mp3';

      final dio = Dio();
      await dio.download(
        directAudioUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              downloadProgress = received / total;
            });
          }
        },
      );

      // Обновляем список треков во всем приложении!
      ref.invalidate(getAllMusicProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Трек "$trackName" успешно скачан и добавлен в медиатеку! 🎧'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка скачивания: $e'),
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

  void _showDirectDownloadDialog() {
    final linkController = TextEditingController();
    final nameController = TextEditingController(text: 'Скачанный трек');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Скачать MP3 файл 🎧', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: linkController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Прямая ссылка на MP3/Аудио',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Название трека',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.backgroundDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (linkController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _downloadAudioFile(linkController.text.trim(), nameController.text.trim());
                }
              },
              child: const Text('Скачать', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя поисковая строка в стиле iOS/Browser как на скриншоте
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  decoration: InputDecoration(
                    hintText: 'Веб-поиск или имя сайта',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 15),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryColor),
                      onPressed: () => _navigateToUrl(urlController.text),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),
            // Индикатор процесса скачивания при активной загрузке
            if (isDownloading)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryColor),
                    ),
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
            // Основной контент (Сетка "Закладки" точь-в-точь по референсу)
            Expanded(
              child: ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text(
                    'Закладки',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Сетка сайтов 4 колонки
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
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
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: (b['color'] as Color).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: (b['color'] as Color).withOpacity(0.35), width: 1.5),
                              ),
                              child: Icon(
                                b['icon'] as IconData,
                                color: b['color'] as Color,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              b['title'] as String,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  // Кнопка прямой загрузки MP3 файлов
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.download_rounded, color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Авто-скачивание в треки 🎧',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Вставьте прямую ссылку для мгновенного сохранения MP3.',
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
                          onPressed: _showDirectDownloadDialog,
                          child: const Text('Ссылка 📥', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            // Нижняя панель управления встроенным браузером (Назад, Вперед, Поделиться, Загрузки, Окна)
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
                    tooltip: 'Назад',
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => _navigateToUrl('https://www.google.com'),
                  ),
                  IconButton(
                    tooltip: 'Вперед',
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 20),
                    onPressed: () {},
                  ),
                  IconButton(
                    tooltip: 'Открыть браузер',
                    icon: const Icon(Icons.ios_share_rounded, color: AppTheme.primaryColor, size: 22),
                    onPressed: () => _navigateToUrl(urlController.text.isNotEmpty ? urlController.text : 'https://www.google.com'),
                  ),
                  IconButton(
                    tooltip: 'Скачать MP3',
                    icon: const Icon(Icons.downloading_rounded, color: AppTheme.accentPink, size: 24),
                    onPressed: _showDirectDownloadDialog,
                  ),
                  IconButton(
                    tooltip: 'Закладки',
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
