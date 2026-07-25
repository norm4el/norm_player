import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Цветовая палитра Norm Player (OLED Black, Slate & Electric Neon Blue как на референсе)
  static const Color backgroundDark = Color(0xFF07070B);
  static const Color surfaceDark = Color(0xFF13131F);
  static const Color surfaceGlass = Color(0xDD151524);
  static const Color primaryColor = Color(0xFF3D7EFF); // Неоновый синий акцент как на скриншоте
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentPink = Color(0xFFFF2E93);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8D8D9E);
  static const Color borderColor = Color(0xFF222234);

  // Основная тема приложения
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentCyan,
        surface: surfaceDark,
        onPrimary: textPrimary,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(color: textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.outfit(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 14, fontWeight: FontWeight.normal),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
        ),
      ),
    );
  }

  // Стили для карточек (Modern Slate Decoration)
  static BoxDecoration glassDecoration({double radius = 20, Color? color}) {
    return BoxDecoration(
      color: color ?? surfaceDark,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

