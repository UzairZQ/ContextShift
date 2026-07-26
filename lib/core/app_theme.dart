import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ContextShift palette: deep-space navy with a single ice-cyan
  // intelligence accent (matches the launcher mark), one warm live accent,
  // and calm semantic colors. No competing hue families.
  static const Color background = Color(0xFF060B16);
  static const Color primary = Color(0xFF63E7FF); // Ice cyan — JARVIS
  static const Color primaryDim = Color(0xFF3BC5E8);
  static const Color primaryContainer = Color(0xFF10405A);
  static const Color accent = Color(0xFFFF7D8A); // Live / recording coral
  static const Color secondary = Color(0xFF16325E); // Deep indigo support
  static const Color tertiary = Color(0xFF9DAAFF); // Periwinkle secondary data
  static const Color tertiaryDim = Color(0xFF8090F2);
  static const Color intelligence = primary;
  static const Color intelligenceDim = primaryDim;

  // Surface hierarchy (blue-tinted layered depth)
  static const Color surface = Color(0xFF060B16); // Base layer
  static const Color surfaceLow = Color(0xFF0A1120); // Sectional layer
  static const Color surfaceContainer = Color(0xFF0F182C); // Card layer
  static const Color surfaceHigh = Color(0xFF15203A); // Container high
  static const Color surfaceHighest = Color(0xFF1B2946); // Container highest
  static const Color surfaceBright = Color(0xFF233457); // Highlight layer

  // Text/Icon colors
  static const Color onSurface = Color(0xFFE9F1FD);
  static const Color onSurfaceVariant = Color(0xFF9DAEC9);
  static const Color outlineVariant = Color(0x264A5B7A); // ghost border

  // Semantic colors
  static const Color success = Color(0xFF54E2A7); // Mint, same family
  static const Color warning = Color(0xFFFFC466);
  static const Color error = Color(0xFFFF7B7B);

  // Gradients — one system: cyan light sweep, used sparingly.
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

  static BoxDecoration contextPanel({
    Color? color,
    double borderRadius = 20,
    Color? accent,
    double accentOpacity = 0.12,
  }) {
    final panelColor = color ?? surfaceContainer;
    return BoxDecoration(
      color: panelColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (accent ?? Colors.white).withValues(
          alpha: accent == null ? 0.07 : accentOpacity,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 26,
          offset: const Offset(0, 14),
          spreadRadius: -18,
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
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHigh.withValues(alpha: 0.96),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        contentTextStyle: GoogleFonts.manrope(
          color: onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: primary.withValues(alpha: 0.28)),
        ),
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
        bodyLarge: GoogleFonts.manrope(fontSize: 16, color: onSurfaceVariant),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, color: onSurfaceVariant),
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
