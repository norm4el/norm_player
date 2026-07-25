import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MusicSortOption {
  dateAdded,
  titleAsc,
  artistAsc,
}

final musicSortOptionProvider = StateProvider<MusicSortOption>((ref) => MusicSortOption.dateAdded);
