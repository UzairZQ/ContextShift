import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Stitch Design Palette: "The Neon Nocturne"
  static const Color background = Color(0xFF0D0D1A);
  static const Color primary = Color(0xFFFF8C96); // Soft Red-Pink
  static const Color primaryDim = Color(0xFFFF6E80);
  static const Color primaryContainer = Color(0xFFFF7484);
  static const Color accent = Color(0xFFE94560); // Vibrant Crimson
  static const Color secondary = Color(0xFF0F3460); // Deep Indigo
  static const Color tertiary = Color(0xFFBB9AFF); // Purple accent
  static const Color tertiaryDim = Color(0xFFAE8AF7);

  // Surface hierarchy (layered depth)
  static const Color surface = Color(0xFF0D0D1A);        // Base Layer
  static const Color surfaceLow = Color(0xFF121220);      // Sectional Layer
  static const Color surfaceContainer = Color(0xFF181828); // Card Layer
  static const Color surfaceHigh = Color(0xFF1E1E2F);     // Container High
  static const Color surfaceHighest = Color(0xFF242437);   // Container Highest
  static const Color surfaceBright = Color(0xFF2A2A3F);    // Highlight Layer

  // Text/Icon colors
  static const Color onSurface = Color(0xFFE9E6F9);
  static const Color onSurfaceVariant = Color(0xFFABA9BB);
  static const Color outlineVariant = Color(0x26474656); // 15% opacity ghost border

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFFF7351);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDim, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tertiaryGradient = LinearGradient(
    colors: [tertiaryDim, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism decoration helper
  static BoxDecoration glassmorphism({
    Color? tint,
    double opacity = 0.6,
    double borderRadius = 24,
  }) {
    return BoxDecoration(
      color: (tint ?? surfaceContainer).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.06),
          blurRadius: 40,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Card decoration (no borders, tonal shift)
  static BoxDecoration cardDecoration({
    Color? color,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: color ?? surfaceHigh,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        onSurface: onSurface,
        surfaceContainer: surfaceContainer,
        outlineVariant: outlineVariant,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          color: onSurface,
          letterSpacing: -1.5,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -1,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
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
        labelMedium: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
      ),
      useMaterial3: true,
    );
  }
}
