import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viola/data/data_source/online_music/online_music_service.dart';
import 'package:viola/presentation/providers/online_music_provider/online_music_provider.dart';
import 'package:viola/utils/theme/app_theme.dart';

class OnlineSearchPage extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const OnlineSearchPage({super.key, required this.scrollController});

  @override
  ConsumerState<OnlineSearchPage> createState() => _OnlineSearchPageState();
}

class _OnlineSearchPageState extends ConsumerState<OnlineSearchPage> {
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(onlineSearchProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentCyan.withOpacity(0.5)),
              ),
              child: const Icon(Icons.cloud_download, color: AppTheme.accentCyan, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Облако / Скачать',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: textEditingController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (value) {
                ref.read(onlineSearchProvider.notifier).searchSongs(value);
              },
              onChanged: (value) {
                if (value.length > 2) {
                  ref.read(onlineSearchProvider.notifier).searchSongs(value);
                } else if (value.isEmpty) {
                  ref.read(onlineSearchProvider.notifier).searchSongs('');
                }
              },
              decoration: InputDecoration(
                hintText: 'Поиск треков, артистов в интернете...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                fillColor: AppTheme.surfaceDark,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: const BorderSide(color: AppTheme.accentCyan),
                ),
                prefixIcon: const Icon(Icons.search, color: AppTheme.accentCyan),
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          textEditingController.clear();
                          ref.read(onlineSearchProvider.notifier).searchSongs('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: searchState.when(
              data: (songs) {
                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_queue, size: 80, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        Text(
                          'Введите название песни или исполнителя\nдля поиска и скачивания в MP3',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.only(bottom: 110, left: 12, right: 12),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: AppTheme.glassDecoration(radius: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: song.artworkUrl.isNotEmpty
                              ? Image.network(
                                  song.artworkUrl,
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 55,
                                    height: 55,
                                    color: AppTheme.primaryColor.withOpacity(0.3),
                                    child: const Icon(Icons.music_note, color: Colors.white),
                                  ),
                                )
                              : Container(
                                  width: 55,
                                  height: 55,
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  child: const Icon(Icons.music_note, color: Colors.white),
                                ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${song.artist} • ${song.album}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: _buildDownloadButton(song),
                      ),
                    );
                  },
                );
              },
              error: (err, st) => Center(
                child: Text('Ошибка поиска: $err', style: const TextStyle(color: Colors.red)),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accentCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(OnlineSong song) {
    if (song.isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green),
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
        width: 45,
        height: 45,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: song.downloadProgress > 0 ? song.downloadProgress : null,
              color: AppTheme.accentCyan,
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
      tooltip: 'Скачать в локальный плеер',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentCyan]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
      ),
      onPressed: () {
        ref.read(onlineSearchProvider.notifier).downloadSong(song);
      },
    );
  }
}
