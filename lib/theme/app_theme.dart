import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NHRColors {
  // ── Core Palette ──
  static const Color milk = Color(0xFFFFF3E6);         // Warm cream — primary bg
  static const Color milkDeep = Color(0xFFF5E6D0);     // Slightly deeper milk for cards
  static const Color dusty = Color(0xFF6B6B6B);         // Dusty grey — secondary text
  static const Color charcoal = Color(0xFF2A2A2A);      // Near-black — headings
  static const Color fog = Color(0xFFE8E0D8);           // Warm fog — dividers, borders

  // ── Muted Accents ──
  static const Color sage = Color(0xFF8FB996);           // Muted sage green
  static const Color terracotta = Color(0xFFC4785B);     // Warm terracotta
  static const Color slate = Color(0xFF7B8FA1);          // Soft slate blue
  static const Color sand = Color(0xFFD4B896);           // Warm sand

  // ── Semantic ──
  static const Color priorityHigh = terracotta;
  static const Color priorityMedium = slate;
  static const Color priorityLow = sage;

  // ── Legacy Backwards Compat (so other files don't break during migration) ──
  static const Color plum = charcoal;
  static const Color plumLight = dusty;
  static const Color plumDark = charcoal;
  static const Color cardBg = milkDeep;
  static const Color cardBgLight = fog;
  static const Color textPrimary = charcoal;
  static const Color textSecondary = dusty;
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color milkMuted = dusty;
  static const Color darkBg = milk;

  static const Color accentPeach = terracotta;
  static const Color accentLavender = slate;
  static const Color accentMint = sage;
  static const Color accentCyan = slate;
  static const Color accentGold = sand;
  static const Color accentRose = terracotta;
  static const Color ironRed = terracotta;
  static const Color ironGold = sand;
  static const Color avengersBlue = slate;
  static const Color xpGreen = sage;
  static const Color neonCyan = slate;
  static const Color streakOrange = terracotta;
  static const Color cosmicPurple = slate;
  static const Color priorityMediumAccent = slate;

  static const LinearGradient heroGradient = LinearGradient(
    colors: [milk, milkDeep],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [sand, milk],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Keep old name as alias so imports don't break during migration
typedef MarvelColors = NHRColors;

class AppTheme {
  static ThemeData get darkTheme => lightTheme; // Redirect old calls

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: NHRColors.milk,
      primaryColor: NHRColors.charcoal,

      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(color: NHRColors.charcoal, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.1),
        displayMedium: GoogleFonts.poppins(color: NHRColors.charcoal, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8),
        headlineMedium: GoogleFonts.poppins(color: NHRColors.charcoal, fontSize: 22, fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.poppins(color: NHRColors.charcoal, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.inter(color: NHRColors.charcoal, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: NHRColors.charcoal, fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(color: NHRColors.charcoal, fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: NHRColors.charcoal, fontSize: 15),
        bodyMedium: GoogleFonts.inter(color: NHRColors.dusty, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: NHRColors.dusty, fontSize: 12),
        labelLarge: GoogleFonts.inter(color: NHRColors.charcoal, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5),
      ),

      colorScheme: const ColorScheme.light(
        primary: NHRColors.charcoal,
        secondary: NHRColors.terracotta,
        surface: NHRColors.milk,
        error: NHRColors.terracotta,
        onPrimary: NHRColors.milk,
        onSurface: NHRColors.charcoal,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: NHRColors.milk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: NHRColors.charcoal),
        titleTextStyle: GoogleFonts.poppins(color: NHRColors.charcoal, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NHRColors.charcoal,
          foregroundColor: NHRColors.milk,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NHRColors.charcoal,
          side: const BorderSide(color: NHRColors.fog, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),

      cardTheme: CardThemeData(
        color: NHRColors.milk,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      dividerTheme: const DividerThemeData(color: NHRColors.fog, thickness: 1, space: 0),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NHRColors.milkDeep,
        hintStyle: GoogleFonts.inter(color: NHRColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NHRColors.fog)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: NHRColors.charcoal, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NHRColors.charcoal,
        foregroundColor: NHRColors.milk,
        elevation: 2,
        shape: CircleBorder(),
      ),
    );
  }
}
