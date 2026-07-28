import 'package:flutter/material.dart';

class AppTheme {
  // ContextShift palette: private sanctuary with warm human action.
  static const Color background = Color(0xFF0D0D1A);
  static const Color primary = Color(0xFFFF8C96); // Soft Red-Pink
  static const Color primaryDim = Color(0xFFFF6E80);
  static const Color primaryContainer = Color(0xFFFF7484);
  static const Color accent = Color(0xFFE94560); // Vibrant Crimson
  static const Color secondary = Color(0xFF0F3460); // Deep Indigo
  static const Color tertiary = Color(0xFFBB9AFF); // Purple accent
  static const Color tertiaryDim = Color(0xFFAE8AF7);
  static const Color intelligence = primary;
  static const Color intelligenceDim = primaryDim;

  // Surface hierarchy (layered depth)
  static const Color surface = Color(0xFF0D0D1A); // Base Layer
  static const Color surfaceLow = Color(0xFF121220); // Sectional Layer
  static const Color surfaceContainer = Color(0xFF181828); // Card Layer
  static const Color surfaceHigh = Color(0xFF1E1E2F); // Container High
  static const Color surfaceHighest = Color(0xFF242437); // Container Highest
  static const Color surfaceBright = Color(0xFF2A2A3F); // Highlight Layer

  // Text/Icon colors
  static const Color onSurface = Color(0xFFE9E6F9);
  static const Color onSurfaceVariant = Color(0xFFABA9BB);
  static const Color outlineVariant = Color(
    0x26474656,
  ); // 15% opacity ghost border

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
        contentTextStyle: const TextStyle(
          fontFamily: 'Manrope',
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
        displayLarge: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 56,
          fontWeight: FontWeight.bold,
          color: onSurface,
          letterSpacing: -1.5,
        ),
        headlineLarge: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -1,
        ),
        headlineMedium: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineSmall: const TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleLarge: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          color: onSurfaceVariant,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          color: onSurfaceVariant,
        ),
        labelSmall: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12,
          color: onSurfaceVariant,
          letterSpacing: 0.5,
        ),
        labelMedium: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onSurfaceVariant,
        ),
      ),
      useMaterial3: true,
    );
  }
}
