import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OnlineSong {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artworkUrl;
  final String downloadUrl;
  bool isDownloading;
  double downloadProgress;
  bool isDownloaded;

  OnlineSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artworkUrl,
    required this.downloadUrl,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isDownloaded = false,
  });

  factory OnlineSong.fromITunesJson(Map<String, dynamic> json) {
    String artwork = json['artworkUrl100'] ?? '';
    if (artwork.isNotEmpty) {
      artwork = artwork.replaceAll('100x100bb', '600x600bb');
    }
    return OnlineSong(
      id: (json['trackId'] ?? 0).toString(),
      title: json['trackName'] ?? 'Unknown Title',
      artist: json['artistName'] ?? 'Unknown Artist',
      album: json['collectionName'] ?? 'Single',
      artworkUrl: artwork,
      downloadUrl: json['previewUrl'] ?? '',
    );
  }
}

class OnlineMusicService {
  static Future<List<OnlineSong>> searchOnline(String query) async {
    if (query.trim().isEmpty) return [];
    
    final encodedQuery = Uri.encodeComponent(query.trim());
    final url = Uri.parse('https://itunes.apple.com/search?term=$encodedQuery&media=music&limit=35');

    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        
        final songs = results
            .where((item) => item['previewUrl'] != null && item['trackName'] != null)
            .map((item) => OnlineSong.fromITunesJson(item))
            .toList();

        // Проверяем, какие файлы уже скачаны
        await _checkDownloadedStatus(songs);
        return songs;
      }
    } catch (e) {
      log('Error searching online music: $e');
    }
    return [];
  }

  static Future<void> _checkDownloadedStatus(List<OnlineSong> songs) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final norm_playerDir = Directory('${appDir.path}/NormMusic');
      if (!await norm_playerDir.exists()) return;

      final files = norm_playerDir.listSync();
      final fileNames = files.map((f) => f.path.split('/').last.split('\\').last.toLowerCase()).toSet();

      for (var song in songs) {
        final expectedName1 = '${_sanitizeFilename(song.title)} - ${_sanitizeFilename(song.artist)}.mp3'.toLowerCase();
        final expectedName2 = '${_sanitizeFilename(song.title)} - ${_sanitizeFilename(song.artist)}.m4a'.toLowerCase();
        if (fileNames.contains(expectedName1) || fileNames.contains(expectedName2)) {
          song.isDownloaded = true;
        }
      }
    } catch (e) {
      log('Error checking downloaded status: $e');
    }
  }

  static String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Future<bool> downloadSong({
    required OnlineSong song,
    required Function(double progress) onProgress,
  }) async {
    if (song.downloadUrl.isEmpty) return false;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final norm_playerDir = Directory('${appDir.path}/NormMusic');
      if (!await norm_playerDir.exists()) {
        await norm_playerDir.create(recursive: true);
      }

      // Определяем расширение из ссылки или по умолчанию .m4a/.mp3
      String ext = '.m4a';
      if (song.downloadUrl.endsWith('.mp3')) ext = '.mp3';

      final fileName = '${_sanitizeFilename(song.title)} - ${_sanitizeFilename(song.artist)}$ext';
      final savePath = '${norm_playerDir.path}/$fileName';

      final dio = Dio();
      await dio.download(
        song.downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      return true;
    } catch (e) {
      log('Error downloading song: $e');
      return false;
    }
  }
}
