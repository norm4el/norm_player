import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/presentation/providers/theme/theme_accent_provider.dart';
import 'package:norm_player/presentation/providers/backup/backup_service.dart';
import 'package:norm_player/presentation/providers/playlists/local_playlists_provider.dart';
import 'package:norm_player/presentation/providers/history/history_provider.dart';
import 'package:norm_player/presentation/providers/analytics/analytics_provider.dart';
import 'package:norm_player/presentation/providers/smart_wave/smart_wave_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:norm_player/presentation/providers/play_list/get_all_music_data.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/presentation/widgets/home_widgets/play_list_tile_widget.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class PlaylistsPage extends ConsumerWidget {
  final ScrollController controller;

  const PlaylistsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(localPlaylistsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          controller: controller,
          slivers: [
            // Шапка "Плейлисты"
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
                          'Плейлисты',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${playlists.length} локальных списков',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Акцентный цвет темы 🎨',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ref.watch(themeAccentProvider).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.palette_rounded, color: ref.watch(themeAccentProvider), size: 22),
                          ),
                          onPressed: () => _showThemePaletteModal(context, ref),
                        ),
                        IconButton(
                          tooltip: 'Резервная копия (Бэкап) 💾',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPink.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.save_alt_rounded, color: AppTheme.accentPink, size: 22),
                          ),
                          onPressed: () async {
                            final path = await BackupService.exportBackup();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(path != null ? 'Бэкап сохранен в $path 💾' : 'Ошибка сохранения бэкапа'),
                                  backgroundColor: AppTheme.surfaceDark,
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Статистика плеера 📊',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.insights_rounded, color: AppTheme.accentColor, size: 24),
                          ),
                          onPressed: () => _showAnalyticsModal(context, ref),
                        ),
                        IconButton(
                          tooltip: 'Создать плейлист',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 24),
                          ),
                          onPressed: () => _showCreatePlaylistDialog(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Карточка "Умная волна ⚡" (Smart Wave Offline Radio)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: GestureDetector(
                  onTap: () async {
                    final success = await ref.read(smartWaveProvider).startSmartWave();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Запущена Умная волна: микс из похожих альбомов и исполнителей ⚡'
                                : 'Добавьте музыку в медиатеку для запуска Умной волны',
                          ),
                          backgroundColor: AppTheme.surfaceDark,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.accentColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Умная волна',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.bolt, color: Colors.amber, size: 20),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Офлайн микс из совпадающих альбомов и исполнителей',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Офлайн миксы по настроению (Mood Playlists)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMoodChip(context, ref, '⚡ Энергия', Colors.orangeAccent),
                      const SizedBox(width: 10),
                      _buildMoodChip(context, ref, '🌙 Релакс', Colors.purpleAccent),
                      const SizedBox(width: 10),
                      _buildMoodChip(context, ref, '🎧 Фокус', Colors.blueAccent),
                      const SizedBox(width: 10),
                      _buildMoodChip(context, ref, '🔥 Топ Чарт', Colors.redAccent),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Text(
                  'Ваши плейлисты',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Список плейлистов
            if (playlists.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Нет созданных плейлистов',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: playlists.length,
                  (context, index) {
                    final playlist = playlists[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.queue_music_rounded, color: AppTheme.primaryColor),
                          ),
                          title: Text(
                            playlist.name,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            '${playlist.songPaths.length} треков',
                            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary),
                            onPressed: () {
                              ref.read(localPlaylistsProvider.notifier).deletePlaylist(playlist.id);
                            },
                          ),
                          onTap: () {
                            _openPlaylistDetails(context, ref, playlist);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Секция "История прослушиваний"
            Builder(builder: (context) {
              final history = ref.watch(historyProvider);
              if (history.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Недавно прослушано',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(historyProvider.notifier).clearHistory();
                            },
                            child: const Text('Очистить', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: history.length > 10 ? 10 : history.length,
                      (context, index) {
                        final item = history[index];
                        return PlayListTile(
                          title: item.title,
                          artist: item.artist,
                          data: item.path,
                          index: index,
                          listOfDatas: history.map((e) => e.path).toList(),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Новый плейлист', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Название (например: Спорт, Ночь...)',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.backgroundDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
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
                if (controller.text.trim().isNotEmpty) {
                  ref.read(localPlaylistsProvider.notifier).createPlaylist(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Создать', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openPlaylistDetails(BuildContext context, WidgetRef ref, LocalPlaylist playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final playlists = ref.watch(localPlaylistsProvider);
            final currentPlaylist = playlists.firstWhere((p) => p.id == playlist.id, orElse: () => playlist);
            final allSongs = ref.watch(getAllMusicProvider).valueOrNull ?? [];
            final playlistSongs = allSongs.where((s) => currentPlaylist.songPaths.contains(s.data)).toList();

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                currentPlaylist.name,
                                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('${playlistSongs.length} треков', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                              label: const Text('Запустить всё ▶', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: playlistSongs.isEmpty
                                  ? null
                                  : () async {
                                      final paths = playlistSongs.map((e) => e.data).toList();
                                      final sources = paths.map((p) => AudioSource.file(p)).toList();
                                      await ref.read(musicPlayerProvider).setAudioSource(
                                            ConcatenatingAudioSource(children: sources),
                                            initialIndex: 0,
                                          );
                                      ref.read(musicPlayerProvider).play();
                                      if (context.mounted) Navigator.pop(context);
                                    },
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              icon: const Icon(Icons.add_rounded, color: AppTheme.primaryColor),
                              label: const Text('Добавить треки', style: TextStyle(color: Colors.white)),
                              onPressed: () => _showAddTracksToPlaylistModal(context, ref, currentPlaylist),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: playlistSongs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.queue_music_rounded, size: 56, color: AppTheme.textSecondary),
                                  const SizedBox(height: 12),
                                  Text(
                                    'В плейлисте пока нет треков.',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Нажмите «Добавить треки» выберите песни из медиатеки.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: playlistSongs.length,
                            itemBuilder: (context, index) {
                              final song = playlistSongs[index];
                              return PlayListTile(
                                title: song.title,
                                artist: song.artist ?? 'Неизвестный исполнитель',
                                data: song.data,
                                index: index,
                                listOfDatas: playlistSongs.map((e) => e.data).toList(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTracksToPlaylistModal(BuildContext context, WidgetRef ref, LocalPlaylist playlist) {
    final allSongs = ref.read(getAllMusicProvider).valueOrNull ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final playlists = ref.watch(localPlaylistsProvider);
            final currentPlaylist = playlists.firstWhere((p) => p.id == playlist.id, orElse: () => playlist);

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Выбор треков для "${currentPlaylist.name}"', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: allSongs.length,
                      itemBuilder: (context, index) {
                        final song = allSongs[index];
                        final isAdded = currentPlaylist.songPaths.contains(song.data);

                        return CheckboxListTile(
                          activeColor: AppTheme.primaryColor,
                          title: Text(song.title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(song.artist ?? 'Исполнитель', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                          value: isAdded,
                          onChanged: (bool? checked) {
                            if (checked == true) {
                              ref.read(localPlaylistsProvider.notifier).addSongToPlaylist(currentPlaylist.id, song.data);
                            } else {
                              ref.read(localPlaylistsProvider.notifier).removeSongFromPlaylist(currentPlaylist.id, song.data);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMoodChip(BuildContext context, WidgetRef ref, String label, Color accentColor) {
    return GestureDetector(
      onTap: () {
        ref.read(smartWaveProvider).startSmartWave();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Запущен офлайн-микс: $label'),
            backgroundColor: AppTheme.surfaceDark,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showAnalyticsModal(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.insights_rounded, color: AppTheme.accentColor, size: 28),
                  const SizedBox(width: 8),
                  Text('Статистика плеера 📊', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${analytics.totalPlays}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                      const SizedBox(height: 4),
                      Text('Всего воспроизведений', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('${analytics.songPlayCounts.length}', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                      const SizedBox(height: 4),
                      Text('Уникальных треков', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showThemePaletteModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final currentColor = ref.watch(themeAccentProvider);
        final accents = [
          {'name': 'Neon Blue ⚡', 'color': ThemeAccentNotifier.electricBlue},
          {'name': 'Cyberpunk Pink 💖', 'color': ThemeAccentNotifier.cyberpunkPink},
          {'name': 'Emerald Green 🟢', 'color': ThemeAccentNotifier.emeraldGreen},
          {'name': 'Sunset Gold 🌟', 'color': ThemeAccentNotifier.sunsetGold},
        ];

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Неоновый акцент темы 🎨', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: accents.map((acc) {
                  final color = acc['color'] as Color;
                  final isSelected = currentColor.value == color.value;
                  return ChoiceChip(
                    label: Text(acc['name'] as String, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: AppTheme.backgroundDark,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(themeAccentProvider.notifier).setAccentColor(color);
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
