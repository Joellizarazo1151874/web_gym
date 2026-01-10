import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.richBlack,
        error: AppColors.error,
        surface: AppColors.white,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      
      // Tipografía
      textTheme: GoogleFonts.rubikTextTheme().copyWith(
        displayLarge: GoogleFonts.catamaran(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          color: AppColors.white,
        ),
        displayMedium: GoogleFonts.catamaran(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: AppColors.richBlack,
        ),
        displaySmall: GoogleFonts.catamaran(
          fontSize: 25,
          fontWeight: FontWeight.w800,
          color: AppColors.richBlack,
        ),
        headlineMedium: GoogleFonts.catamaran(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.richBlack,
        ),
        bodyLarge: GoogleFonts.rubik(
          fontSize: 16,
          color: AppColors.sonicSilver,
        ),
        bodyMedium: GoogleFonts.rubik(
          fontSize: 15,
          color: AppColors.sonicSilver,
        ),
        bodySmall: GoogleFonts.rubik(
          fontSize: 14,
          color: AppColors.sonicSilver,
        ),
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.richBlack),
        titleTextStyle: GoogleFonts.catamaran(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.richBlack,
        ),
      ),
      
      // Botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.rubik(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.rubik(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: AppColors.white,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.sonicSilver,
        selectedLabelStyle: GoogleFonts.rubik(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.rubik(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}

