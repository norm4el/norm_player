import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viola/presentation/providers/search_provider/search.dart';
import 'package:viola/presentation/widgets/home_widgets/play_list_tile_widget.dart';
import 'package:viola/utils/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SearchPage extends ConsumerWidget {
  SearchPage({super.key, required this.scrollController});

  final ScrollController scrollController;
  final TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Icon(Icons.search, color: AppTheme.accentCyan, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Поиск в библиотеке',
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
              onChanged: (value) {
                ref.read(searchProvider.notifier).searchSongs(search: value);
              },
              decoration: InputDecoration(
                hintText: 'Искать локальные треки и плейлисты...',
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
                suffixIcon: IconButton(
                  icon: textEditingController.text.isEmpty
                      ? const Icon(Icons.mic, color: Colors.grey)
                      : const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    textEditingController.clear();
                    ref.invalidate(searchProvider);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: ref.watch(searchProvider).isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.manage_search_rounded, size: 80, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        Text(
                          'Начните вводить название песни из\nвашей офлайн библиотеки',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: ref.watch(searchProvider).length,
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 110, left: 12, right: 12),
                    itemBuilder: (context, index) {
                      final List<SongModel> result = ref.watch(searchProvider);
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: AppTheme.glassDecoration(radius: 16),
                        child: PlayListTile(
                          title: result[index].title,
                          artist: result[index].artist ?? 'unknown',
                          data: result[index].data,
                          index: index,
                          isPlayingFromSearch: true,
                          listOfDatas: result.map((e) => e.data).toList(),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

