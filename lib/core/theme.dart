import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🌌 AURORA NORTHERN LIGHTS COLOR PALETTE
  static const Color primaryColor = Color(0xFF6A11CB);     // Deep Purple Aurora
  static const Color accentColor = Color(0xFF2575FC);      // Blue Aurora
  static const Color deepGold = Color(0xFF00CDAC);         // Teal Aurora
  static const Color backgroundColor = Color(0xFFF8F5FF);  // Very Light Purple
  static const Color surfaceColor = Color(0xFFF3E5F5);     // Light Purple Surface
  static const Color textPrimaryColor = Color(0xFF4A148C); // Deep Purple Text
  static const Color textSecondaryColor = Color(0xFF7B1FA2); // Purple Text

  // 🌈 AURORA GRADIENT (Northern Lights Effect)
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF6A11CB), Color(0xFF2575FC), Color(0xFF00CDAC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ❄️ GLASS MORPHISM DECORATION (Aurora Glass Effect)
  static BoxDecoration get glassDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.15),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF6A11CB).withOpacity(0.1),
        blurRadius: 20,
        spreadRadius: 1,
      ),
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        tertiary: deepGold,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
  color: Colors.white,
  elevation: 8,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
  ),
  margin: const EdgeInsets.all(16),
  shadowColor: Colors.blue.withOpacity(0.2),
  surfaceTintColor: Colors.transparent,
),
    );
  }
}