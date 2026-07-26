import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/domain/entity/songs_entity.dart';
import 'package:norm_player/presentation/providers/favorites/get_id_from_fav/get_music_entity.dart';
import 'package:norm_player/presentation/providers/favorites/is_favorites.dart';
import 'package:norm_player/presentation/providers/current_playing/is_palying.dart';
import 'package:norm_player/presentation/providers/current_playing/music_player_provider.dart';
import 'package:norm_player/presentation/providers/favorites/fav_db_music/music_db.dart';
import 'package:norm_player/presentation/providers/music/get_all_music.dart';
import 'package:norm_player/presentation/providers/search_provider/search.dart';
import 'package:norm_player/presentation/providers/sleep_timer/sleep_timer_provider.dart';
import 'package:norm_player/presentation/providers/bookmarks/bookmarks_provider.dart';
import 'package:norm_player/presentation/providers/equalizer/equalizer_provider.dart';
import 'package:norm_player/presentation/providers/ab_loop/ab_loop_provider.dart';
import 'package:norm_player/presentation/providers/playback_speed/playback_speed_provider.dart';
import 'package:norm_player/presentation/providers/history/history_provider.dart';
import 'package:norm_player/presentation/widgets/lyrics/lyrics_view_widget.dart';
import 'package:norm_player/presentation/widgets/home_widgets/progress_indicator.dart';
import 'package:norm_player/presentation/widgets/visualizer/neon_waveform_widget.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class CurrentPlayingPage extends ConsumerWidget {
  const CurrentPlayingPage({
    super.key,
    this.isPlayingFromFav = false,
    this.isPlayingFromSearch = false,
  });

  final bool isPlayingFromFav;
  final bool isPlayingFromSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isPlaying = ref.watch(isPlayingProvider);
    late List<dynamic> data;
    if (isPlayingFromFav) {
      data = ref.read(musicDbProvider);
    } else if (isPlayingFromSearch) {
      data = ref.read(searchProvider);
    } else {
      data = ref.read(getAllMusicProvider).value!;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Эквалайзер 🎚️',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor, size: 24),
            onPressed: () => _showEqualizerModal(context, ref),
          ),
          Builder(builder: (context) {
            final currentSpeed = ref.watch(playbackSpeedProvider);
            return TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              onPressed: () => _showSpeedModal(context, ref),
              child: Text(
                '${currentSpeed == 1.0 ? '1.0' : currentSpeed}x',
                style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: ref.watch(musicPlayerProvider).currentIndexStream,
          builder: (context, snapShot) {
            final int index = snapShot.data ?? 0;
            final song = (data.isNotEmpty && index < data.length) ? data[index] : null;
            final title = song?.title ?? 'Unknown Track';
            final artist = song?.artist ?? 'Imported Music';
            final String? songDataPath = song?.data;

            if (songDataPath != null && songDataPath.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(historyProvider.notifier).addTrack(
                      title: title,
                      artist: artist,
                      path: songDataPath,
                    );
                final currentPosDuration = ref.read(musicPlayerProvider).position;
                final currentPos = currentPosDuration.inMilliseconds;
                if (currentPos > 5000) {
                  ref.read(bookmarksProvider.notifier).savePosition(songDataPath, currentPos);
                }
                final abState = ref.read(abLoopProvider);
                if (abState.isLooping && abState.pointA != null && abState.pointB != null) {
                  if (currentPosDuration >= abState.pointB!) {
                    ref.read(musicPlayerProvider).seek(abState.pointA!);
                  }
                }
              });
            }
            final bool isFav = (songDataPath != null && songDataPath.isNotEmpty)
                ? ref.watch(isFavProvider(data: songDataPath))
                : false;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(height: 10),
                  // Большая квадратная обложка трека в стиле Apple Music / Spotify
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: MediaQuery.of(context).size.width * 0.85,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.08),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.35),
                                AppTheme.surfaceDark,
                                AppTheme.accentColor.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              color: AppTheme.primaryColor,
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Название трека, исполнитель и кнопка избранного
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppTheme.accentPink : AppTheme.textSecondary,
                          size: 28,
                        ),
                        onPressed: () {
                          if (songDataPath != null && songDataPath.isNotEmpty) {
                            if (isFav) {
                              final favId = ref.read(getMusicEntityProvider(
                                dbSongs: ref.read(musicDbProvider),
                                data: songDataPath,
                              ));
                              ref.read(musicDbProvider.notifier).removeSongs(favId);
                            } else {
                              ref.read(musicDbProvider.notifier).addSongs(
                                SongsEntity(artist: artist, title: title, data: songDataPath),
                              );
                            }
                            ref.invalidate(isFavProvider);
                            ref.invalidate(musicDbProvider);
                          }
                        },
                      ),
                    ],
                  ),
                  // Полоса прогресса
                  const ProgressIndicatingWidget(),
                  // Кнопки управления плеером (Shuffle, Prev, Play/Pause, Next, Repeat)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: AppTheme.textSecondary, size: 22),
                        onPressed: () {
                          ref.read(musicPlayerProvider).setShuffleModeEnabled(true);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
                        onPressed: () {
                          ref.read(musicPlayerProvider).seekToPrevious();
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          if (ref.watch(isPlayingProvider)) {
                            ref.invalidate(isPlayingProvider);
                            ref.read(musicPlayerProvider).pause();
                          } else {
                            ref.invalidate(isPlayingProvider);
                            ref.read(musicPlayerProvider).play();
                          }
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceDark,
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.6), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                        onPressed: () {
                          ref.read(musicPlayerProvider).seekToNext();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat, color: AppTheme.textSecondary, size: 22),
                        onPressed: () {},
                      ),
                    ],
                  ),
                   const SizedBox(height: 12),
                  // Анимированный визуализатор неоновой звуковой волны
                  const NeonWaveformWidget(height: 36, barCount: 22),
                  const SizedBox(height: 12),
                  // Нижняя панель иконок (Таймер сна, Очередь, Эквалайзер)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Builder(builder: (context) {
                        final sleepTimerState = ref.watch(sleepTimerProvider);
                        final bool timerActive = sleepTimerState.isActive;

                        return IconButton(
                          tooltip: 'Таймер сна',
                          icon: Icon(
                            timerActive ? Icons.bedtime_rounded : Icons.bedtime_outlined,
                            color: timerActive ? AppTheme.accentPink : AppTheme.textSecondary,
                            size: 24,
                          ),
                          onPressed: () {
                            _showSleepTimerModal(context, ref);
                          },
                        );
                      }),
                      IconButton(
                        tooltip: 'Текст песни (Lyrics)',
                        icon: const Icon(Icons.lyrics_rounded, color: AppTheme.textSecondary, size: 24),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => OfflineLyricsWidget(title: title, artist: artist),
                          );
                        },
                      ),
                      Builder(builder: (context) {
                        final abLoop = ref.watch(abLoopProvider);
                        final bool isLooping = abLoop.isLooping;

                        return IconButton(
                          tooltip: isLooping ? 'Сбросить повтор A-B' : 'Повтор отрезка A-B',
                          icon: Icon(
                            isLooping ? Icons.repeat_one_on_rounded : Icons.repeat_one_rounded,
                            color: isLooping ? AppTheme.accentColor : AppTheme.textSecondary,
                            size: 24,
                          ),
                          onPressed: () {
                            final currentPos = ref.read(musicPlayerProvider).position;
                            if (abLoop.pointA == null) {
                              ref.read(abLoopProvider.notifier).setPointA(currentPos);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Установлена точка A 📍. Нажмите ещё раз для точки B'), duration: Duration(seconds: 2)),
                              );
                            } else if (abLoop.pointB == null) {
                              ref.read(abLoopProvider.notifier).setPointB(currentPos);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Зациклен отрезок A-B 🔄!'), duration: Duration(seconds: 2)),
                              );
                            } else {
                              ref.read(abLoopProvider.notifier).resetLoop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Повтор отрезка выключен'), duration: Duration(seconds: 1)),
                              );
                            }
                          },
                        );
                      }),
                      IconButton(
                        tooltip: 'Аудио Эквалайзер',
                        icon: const Icon(Icons.tune, color: AppTheme.textSecondary, size: 24),
                        onPressed: () {
                          _showEqualizerModal(context, ref);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSpeedModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final currentSpeed = ref.watch(playbackSpeedProvider);
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Скорость воспроизведения', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: speeds.map((speed) {
                  final isSelected = currentSpeed == speed;
                  return ChoiceChip(
                    label: Text('${speed}x', style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.backgroundDark,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(playbackSpeedProvider.notifier).setSpeed(speed);
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final timerNotifier = ref.read(sleepTimerProvider.notifier);
        final timerState = ref.watch(sleepTimerProvider);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bedtime_rounded, color: AppTheme.accentPink, size: 26),
                  const SizedBox(width: 8),
                  Text(
                    'Таймер сна',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (timerState.isActive) ...[
                const SizedBox(height: 10),
                Text(
                  timerState.untilEndOfTrack
                      ? 'Остановка после окончания трека'
                      : 'Осталось: ${timerState.remainingSeconds! ~/ 60}:${(timerState.remainingSeconds! % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(color: AppTheme.accentPink, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.white),
                title: const Text('15 минут', style: TextStyle(color: Colors.white)),
                onTap: () {
                  timerNotifier.setTimer(15);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: Colors.white),
                title: const Text('30 минут', style: TextStyle(color: Colors.white)),
                onTap: () {
                  timerNotifier.setTimer(30);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_rounded, color: Colors.white),
                title: const Text('60 минут', style: TextStyle(color: Colors.white)),
                onTap: () {
                  timerNotifier.setTimer(60);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.music_note, color: Colors.white),
                title: const Text('В конце текущего трека', style: TextStyle(color: Colors.white)),
                onTap: () {
                  timerNotifier.setUntilEndOfTrack();
                  Navigator.pop(context);
                },
              ),
              if (timerState.isActive)
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.redAccent),
                  title: const Text('Отменить таймер', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () {
                    timerNotifier.cancelTimer();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEqualizerModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final eqState = ref.watch(equalizerProvider);
            final presets = [
              {'label': 'Обычный ⚖️', 'preset': EqualizerPreset.normal},
              {'label': 'Bass Boost 🔊', 'preset': EqualizerPreset.bassBoost},
              {'label': 'Rock 🎸', 'preset': EqualizerPreset.rock},
              {'label': 'Electronic ⚡', 'preset': EqualizerPreset.electronic},
              {'label': 'Vocal 🎤', 'preset': EqualizerPreset.vocal},
            ];

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('Аудио Эквалайзер 🎚️', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((p) {
                      final isSelected = eqState.preset == p['preset'];
                      return ChoiceChip(
                        label: Text(p['label'] as String, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.backgroundDark,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(equalizerProvider.notifier).setPreset(p['preset'] as EqualizerPreset);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Низкие частоты (Басс):', style: TextStyle(color: Colors.white, fontSize: 13)),
                      Expanded(
                        child: Slider(
                          value: eqState.bassGain,
                          activeColor: AppTheme.primaryColor,
                          inactiveColor: AppTheme.backgroundDark,
                          onChanged: (v) => ref.read(equalizerProvider.notifier).setBass(v),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Высокие частоты (Treble):', style: TextStyle(color: Colors.white, fontSize: 13)),
                      Expanded(
                        child: Slider(
                          value: eqState.trebleGain,
                          activeColor: AppTheme.accentPink,
                          inactiveColor: AppTheme.backgroundDark,
                          onChanged: (v) => ref.read(equalizerProvider.notifier).setTreble(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
