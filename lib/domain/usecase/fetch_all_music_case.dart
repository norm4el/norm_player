import 'dart:developer';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:viola/utils/import_helper.dart';

// get all audio files from local storage and imported/downloaded folder

class FetchAudioFiles {
  Future<List<SongModel>> fetchAudio() async {
    final OnAudioQuery audioQuery = OnAudioQuery();
    List<SongModel> songsList = [];
    try {
      songsList = await audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    } catch (e) {
      log('Error querying MediaStore: $e');
    }

    try {
      final localFiles = await ImportHelper.getLocalAudioFiles();
      int customId = 900000;
      for (final file in localFiles) {
        final filename = file.path.split('/').last.split('\\').last;
        final title = filename.contains('.') ? filename.substring(0, filename.lastIndexOf('.')) : filename;
        // Проверяем, нет ли уже этого файла в списке из MediaStore
        if (!songsList.any((s) => s.data == file.path)) {
          final map = {
            '_id': customId++,
            '_data': file.path,
            '_display_name': filename,
            'title': title,
            'artist': 'Viola Offline',
            'album': 'Imported Music',
            'duration': 0,
            'is_music': 1,
          };
          songsList.add(SongModel(map));
        }
      }
      // Сортируем общий список по названию
      songsList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      log('Total songs loaded: ${songsList.length}');
      return songsList;
    } catch (e) {
      log('Error loading local audio files: $e');
      return songsList;
    }
  }
}
