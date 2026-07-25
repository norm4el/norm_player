import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norm_player/presentation/providers/current_playing/is_palying.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

enum VisualizerMode { bars, wave, pulse }

class NeonWaveformWidget extends ConsumerStatefulWidget {
  final double height;
  final int barCount;

  const NeonWaveformWidget({
    super.key,
    this.height = 40,
    this.barCount = 22,
  });

  @override
  ConsumerState<NeonWaveformWidget> createState() => _NeonWaveformWidgetState();
}

class _NeonWaveformWidgetState extends ConsumerState<NeonWaveformWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  VisualizerMode _currentMode = VisualizerMode.bars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      if (_currentMode == VisualizerMode.bars) {
        _currentMode = VisualizerMode.wave;
      } else if (_currentMode == VisualizerMode.wave) {
        _currentMode = VisualizerMode.pulse;
      } else {
        _currentMode = VisualizerMode.bars;
      }
    });

    final modeName = switch (_currentMode) {
      VisualizerMode.bars => '📊 Неоновые Столбцы',
      VisualizerMode.wave => '🌊 Плавная Волна',
      VisualizerMode.pulse => '⭕ Пульсирующий Спектр',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Режим визуализации: $modeName'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppTheme.surfaceDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPlaying = ref.watch(isPlayingProvider);

    return GestureDetector(
      onTap: _toggleMode,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_currentMode == VisualizerMode.pulse) {
            final double pulseScale = isPlaying ? (1.0 + (_controller.value * 0.25)) : 1.0;
            return SizedBox(
              height: widget.height,
              child: Center(
                child: Transform.scale(
                  scale: pulseScale,
                  child: Container(
                    width: widget.height * 0.7,
                    height: widget.height * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentPink],
                      ),
                      boxShadow: isPlaying
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.6),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
              ),
            );
          }

          return SizedBox(
            height: widget.height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(widget.barCount, (index) {
                final double factor = _currentMode == VisualizerMode.wave ? 0.2 : 0.4;
                final double value = isPlaying
                    ? (sin((_controller.value * 2 * pi) + (index * factor)) + 1) / 2
                    : 0.15;
                final double barHeight = max(4.0, widget.height * value);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: _currentMode == VisualizerMode.wave ? 4.5 : 3.5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        _currentMode == VisualizerMode.wave ? AppTheme.accentPink : AppTheme.accentColor,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    boxShadow: isPlaying
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
