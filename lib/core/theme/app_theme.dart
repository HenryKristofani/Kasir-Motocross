import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const asphalt = Color(0xFF1B1B1D);
  static const safetyOrange = Color(0xFFFF5A1F);
  static const dirtTan = Color(0xFFB08D57);
  static const trackWhite = Color(0xFFFAFAF8);
  static const charcoal = Color(0xFF26241F);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.trackWhite,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.safetyOrange,
        primary: AppColors.safetyOrange,
        surface: AppColors.trackWhite,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.asphalt,
        foregroundColor: AppColors.trackWhite,
        titleTextStyle: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.trackWhite,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: TextTheme(
        // Angka besar (total harga) - pakai Oswald, kesan "plat nomor"
        headlineLarge: GoogleFonts.oswald(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.asphalt,
        ),
        headlineMedium: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.asphalt,
        ),
        // Body - Inter, legible untuk list
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.charcoal),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.charcoal),
        titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.charcoal),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.asphalt,
        indicatorColor: AppColors.safetyOrange,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 12, color: AppColors.trackWhite, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.asphalt : AppColors.trackWhite.withValues(alpha: 0.7));
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.safetyOrange,
          foregroundColor: AppColors.trackWhite,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.asphalt.withValues(alpha: 0.08)),
        ),
      ),
    );
  }
}