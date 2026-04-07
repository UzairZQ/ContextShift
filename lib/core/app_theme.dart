import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Stitch Design Palette: "The Neon Nocturne"
  static const Color background = Color(0xFF0D0D1A);
  static const Color primary = Color(0xFFFF8C96); // Soft Red-Pink
  static const Color primaryDim = Color(0xFFFF6E80);
  static const Color secondary = Color(0xFF0F3460); // Deep Indigo
  static const Color accent = Color(0xFFE94560); // Vibrant Crimson
  static const Color surface = Color(0xFF0D0D1A);
  static const Color surfaceLow = Color(0xFF121220);
  static const Color surfaceContainer = Color(0xFF181828);
  static const Color surfaceHigh = Color(0xFF242437);
  static const Color onSurface = Color(0xFFE9E6F9);
  static const Color onSurfaceVariant = Color(0xFFABA9BB);
  static const Color outlineVariant = Color(0x26474656); // 15% opacity ghost border

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        surfaceContainer: surfaceContainer,
        outlineVariant: outlineVariant,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 56, // Editorial scale
          fontWeight: FontWeight.bold,
          color: onSurface,
          letterSpacing: -1.5,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          color: onSurfaceVariant,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          color: onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 12,
          color: onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
      useMaterial3: true,
    );
  }
}
