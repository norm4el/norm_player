import 'package:flutter/material.dart';
import 'package:norm_player/presentation/pages/bottom_navigation/bottom_navigation_page.dart';

import 'package:page_transition/page_transition.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // navigate directly to home screen (MusicBottomSheet)
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        PageTransition(
          child: const MusicBottomSheet(),
          type: PageTransitionType.fade,
        ),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/animations/norm_logo.png",
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            const Text(
              'Norm Player',
              style: TextStyle(
                  fontFamily: 'Pacifico',
                  color: Colors.black,
                  fontSize: 30,
                  fontWeight: FontWeight.w700),
            )
          ],
        ),
      ),
    );
  }
}
