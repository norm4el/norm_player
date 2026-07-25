import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:norm_player/data/data_source/object_box.dart/object_box_impl.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';
import 'presentation/pages/on_boarding/loading_screen/loading_screen.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // create sharepref instace
  SharedPrefImpl.create();
  // Just audio background
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  // await untill create object box
  await ObjectBoxImpl.create();

// run app
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
      /// method for hiding soft keyboard
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        // navigate to loading screen
        home: const LoadingScreen(),
      ),
    );
  }
}
