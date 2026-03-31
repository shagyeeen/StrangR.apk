import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StrangRTheme {
  // Colors mapped directly from Stitch Design System
  static const Color background = Color(0xFF0D0D0D); // Truly deep black
  static const Color surface = Color(0xFF131313);
  static const Color surfaceHighlight = Color(0xFF1E1E1E);
  static const Color primary = Color(0xFFF9B8F9); // Lighter, sharper pink
  static const Color secondary = Color(0xFFF1B2EF);
  static const Color tertiary = Color(0xFF96FFA7);
  static const Color primaryContainer = Color(0xFFF6B7F6);
  static const Color onPrimary = Color(0xFF4C1D51);
  
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color onSurfaceVariant = Color(0xFFAAAAAA);
  
  // Custom Glow Effects
  static List<BoxShadow> get centralGlow => [
        BoxShadow(
          color: primary.withOpacity(0.08),
          blurRadius: 100,
          spreadRadius: 20,
        )
      ];

  // Font Theme
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic, // Web app style
        color: onSurface,
        letterSpacing: -2.0,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: onSurface,
        letterSpacing: -1.0,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: onSurface.withOpacity(0.6),
      ),
    );
  }

  // ThemeData Instance
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        onSurface: onSurface,
      ),
      textTheme: textTheme,
      useMaterial3: true,
    );
  }
}
