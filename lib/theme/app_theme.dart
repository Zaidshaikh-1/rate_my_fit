import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core palette — Ultra-modern midnight aesthetic
  static const background = Color(0xFF09090E); // Deep space black
  static const surface = Color(0xFF13131A); // Elevated dark
  static const surfaceCard = Color(0xFF1B1B25); // Card surface
  static const border = Color(0xFF2A2A38); // Subtle borders

  static const primary = Color(0xFFFFE040); // Hot Yellow
  static const primaryDark = Color(0xFFB8A000);

  static const textPrimary = Color(0xFFF8F8F8);
  static const textSecondary = Color(0xFFA0A0AB);
  static const textMuted = Color(0xFF5A5A66);

  // Vibe card colours
  static const drip = Color(0xFFFF4D4D); // 🔥
  static const clean = Color(0xFF4DFFB4); // 😎
  static const mid = Color(0xFFFFAA00); // 😐
  static const notIt = Color(0xFF7B7B7B); // 💀
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        onPrimary: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: GoogleFonts.syneTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(bodyMedium: const TextStyle(color: AppColors.textPrimary)),
    );
  }
}
