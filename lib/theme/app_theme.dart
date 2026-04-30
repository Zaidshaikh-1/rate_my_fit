import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core palette — dark streetwear aesthetic
  static const background   = Color(0xFF0A0A0A);
  static const surface      = Color(0xFF141414);
  static const surfaceCard  = Color(0xFF1C1C1C);
  static const border       = Color(0xFF2A2A2A);

  static const primary      = Color(0xFFFFE040); // hot yellow
  static const primaryDark  = Color(0xFFB8A000);

  static const textPrimary  = Color(0xFFF5F5F5);
  static const textSecondary= Color(0xFF888888);
  static const textMuted    = Color(0xFF444444);

  // Vibe card colours
  static const drip         = Color(0xFFFF4D4D); // 🔥
  static const clean        = Color(0xFF4DFFB4); // 😎
  static const mid          = Color(0xFFFFAA00); // 😐
  static const notIt        = Color(0xFF7B7B7B); // 💀
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
          fontSize: 20,
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
      textTheme: GoogleFonts.syneTextTheme(ThemeData.dark().textTheme),
    );
  }
}
