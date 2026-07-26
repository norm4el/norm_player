import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/object_box.dart/object_box_impl.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';
import 'presentation/pages/on_boarding/loading_screen/loading_screen.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 1. Await SharedPreferences initialization to prevent LateInitializationError
    await SharedPrefImpl.create();
  } catch (e) {
    debugPrint('SharedPrefImpl init error: $e');
  }

  try {
    // 2. JustAudioBackground init
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.norm_player.bg.channel.audio',
      androidNotificationChannelName: 'Norm Player Audio Playback',
      androidNotificationOngoing: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground init error: $e');
  }

  try {
    // 3. ObjectBox init
    await ObjectBoxImpl.create();
  } catch (e) {
    debugPrint('ObjectBoxImpl init error: $e');
  }

  // 4. Run app safely
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const LoadingScreen(),
      ),
    );
  }
}
