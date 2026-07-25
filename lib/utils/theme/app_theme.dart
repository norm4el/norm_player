import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Цветовая палитра премиального стиля (Dark Neon & Glassmorphism)
  static const Color backgroundDark = Color(0xFF0B0B14);
  static const Color surfaceDark = Color(0xFF161626);
  static const Color surfaceGlass = Color(0xCC1D1D33);
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentPink = Color(0xFFFF007F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0B8);
  static const Color borderColor = Color(0xFF2A2A44);

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
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
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
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
    );
  }

  // Стили для стеклянных карточек (Glassmorphism Decoration)
  static BoxDecoration glassDecoration({double radius = 20, Color? color}) {
    return BoxDecoration(
      color: color ?? surfaceGlass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
