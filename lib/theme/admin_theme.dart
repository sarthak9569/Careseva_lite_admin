import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Dark Command Center Theme Palette
  static const scaffoldBg = Color(0xFF0B0F19);
  static const cardBg = Color(0xFF131825);
  static const cardBorder = Color(0xFF1E2638);
  static const headerBg = Color(0xFF0B0F19);
  
  static const primaryColor = Color(0xFF0D9488); // Teal
  static const accentColor = Color(0xFF0EA5E9); // Cyan / Sky
  
  // Status & Metric Accent Colors
  static const pendingGold = Color(0xFFF59E0B);
  static const approvedGreen = Color(0xFF10B981);
  static const cyanBeds = Color(0xFF06B6D4);
  static const accreditedPurple = Color(0xFF8B5CF6);
  static const rejectedRed = Color(0xFFEF4444);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: scaffoldBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: cardBg,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      titleLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(color: textPrimary),
      bodyMedium: GoogleFonts.inter(color: textSecondary),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: headerBg,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: cardBorder, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF161C2C),
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor),
      ),
    ),
  );
}

