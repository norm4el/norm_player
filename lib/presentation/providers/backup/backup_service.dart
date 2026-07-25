import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:norm_player/data/data_source/shared_preferences/shared_perf.dart';

class BackupService {
  static Future<String?> exportBackup() async {
    try {
      final Map<String, dynamic> backupData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'playlists': SharedPrefImpl.pref.getString('user_local_playlists_json'),
        'history': SharedPrefImpl.pref.getString('user_music_history_json'),
        'tags': SharedPrefImpl.pref.getString('user_song_tag_overrides_json'),
        'analytics': SharedPrefImpl.pref.getString('user_music_analytics_json'),
      };

      final dir = await getApplicationDocumentsDirectory();
      final backupFile = File('${dir.path}/NormPlayer_Backup.json');
      await backupFile.writeAsString(jsonEncode(backupData));
      return backupFile.path;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> importBackup(String jsonContent) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);
      if (data['playlists'] != null) {
        SharedPrefImpl.pref.setString('user_local_playlists_json', data['playlists']);
      }
      if (data['history'] != null) {
        SharedPrefImpl.pref.setString('user_music_history_json', data['history']);
      }
      if (data['tags'] != null) {
        SharedPrefImpl.pref.setString('user_song_tag_overrides_json', data['tags']);
      }
      if (data['analytics'] != null) {
        SharedPrefImpl.pref.setString('user_music_analytics_json', data['analytics']);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
