import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:viola/presentation/providers/music/get_all_music.dart';

class ImportHelper {
  static Future<void> importAudioFiles(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'flac', 'aac', 'ogg'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final violaDir = Directory('${appDir.path}/ViolaMusic');
        if (!await violaDir.exists()) {
          await violaDir.create(recursive: true);
        }

        int count = 0;
        for (final file in result.files) {
          if (file.path != null) {
            final sourceFile = File(file.path!);
            final targetPath = '${violaDir.path}/${file.name}';
            await sourceFile.copy(targetPath);
            count++;
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Успешно импортировано треков: $count'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Обновляем список музыки в приложении
        ref.invalidate(getAllMusicProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка импорта музыки: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<List<File>> getLocalAudioFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final violaDir = Directory('${appDir.path}/ViolaMusic');
      if (!await violaDir.exists()) {
        return [];
      }
      final files = violaDir.listSync();
      return files
          .whereType<File>()
          .where((file) {
            final path = file.path.toLowerCase();
            return path.endsWith('.mp3') ||
                path.endsWith('.m4a') ||
                path.endsWith('.wav') ||
                path.endsWith('.flac') ||
                path.endsWith('.aac') ||
                path.endsWith('.ogg');
          })
          .toList();
    } catch (e) {
      return [];
    }
  }
}
