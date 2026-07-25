import 'package:flutter/material.dart';
import 'package:viola/presentation/pages/favorite/favorites_page.dart';
import 'package:viola/presentation/pages/home/home_page.dart';
import 'package:viola/presentation/pages/search/search_page.dart';
import 'package:viola/presentation/pages/online_search/online_search_page.dart';
import 'package:viola/utils/dynamic_sizes/dynamic_sizes.dart';
import 'package:viola/utils/theme/app_theme.dart';
import 'package:scroll_to_hide/scroll_to_hide.dart';

class MusicBottomSheet extends StatefulWidget {
  const MusicBottomSheet({super.key});

  @override
  State<MusicBottomSheet> createState() => _MusicBottomSheetState();
}

class _MusicBottomSheetState extends State<MusicBottomSheet> {
  // scroll controller for scrollToHide package
  final ScrollController _scrollController = ScrollController();

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // pages for navigate throw
    List<Widget> pages = [
      HomePage(scrollController: _scrollController),
      SearchPage(scrollController: _scrollController),
      OnlineSearchPage(scrollController: _scrollController),
      FavoritePage(controller: _scrollController),
    ];
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // shows selected page
          pages[currentIndex],
          // scroll to hide methods
          Positioned(
            left: context.screenWidth(20),
            right: context.screenWidth(20),
            bottom: context.screenHeight(-15),
            child: ScrollToHide(
              height: 80,
              duration: const Duration(milliseconds: 500),
              scrollController: _scrollController,
              hideDirection: Axis.vertical,
              child: Container(
                decoration: AppTheme.glassDecoration(radius: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BottomNavigationBar(
                    currentIndex: currentIndex,
                    type: BottomNavigationBarType.fixed,
                    showUnselectedLabels: true,
                    selectedLabelStyle: const TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    onTap: (value) {
                      setState(() {
                        currentIndex = value;
                      });
                    },
                    backgroundColor: AppTheme.surfaceDark.withOpacity(0.95),
                    selectedItemColor: AppTheme.accentCyan,
                    unselectedItemColor: AppTheme.textSecondary,
                    elevation: 0,
                    iconSize: 26,
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.home_rounded), label: 'Плеер', tooltip: 'Плеер'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.search_rounded), label: 'Локальные', tooltip: 'Локальный поиск'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.cloud_download_rounded), label: 'Интернет', tooltip: 'Онлайн загрузка'),
                      BottomNavigationBarItem(
                          icon: Icon(Icons.favorite_rounded), label: 'Избранное', tooltip: 'Избранное'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
