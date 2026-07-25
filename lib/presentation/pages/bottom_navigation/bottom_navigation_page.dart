import 'package:flutter/material.dart';
import 'package:norm_player/presentation/pages/favorite/favorites_page.dart';
import 'package:norm_player/presentation/pages/home/home_page.dart';
import 'package:norm_player/presentation/pages/search/search_page.dart';
import 'package:norm_player/presentation/pages/online_search/online_search_page.dart';
import 'package:norm_player/utils/theme/app_theme.dart';

class MusicBottomSheet extends StatefulWidget {
  const MusicBottomSheet({super.key});

  @override
  State<MusicBottomSheet> createState() => _MusicBottomSheetState();
}

class _MusicBottomSheetState extends State<MusicBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      HomePage(scrollController: _scrollController),
      SearchPage(scrollController: _scrollController),
      OnlineSearchPage(scrollController: _scrollController),
      FavoritePage(controller: _scrollController),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundDark,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, Icons.home_outlined),
                _buildNavItem(1, Icons.search_rounded, Icons.search),
                _buildNavItem(2, Icons.cloud_download_rounded, Icons.cloud_download_outlined),
                _buildNavItem(3, Icons.favorite, Icons.favorite_border),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}
