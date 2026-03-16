import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────
//  WRAPD — Design Token System (The Law)
//  All magic numbers are forbidden. Use these tokens only.
// ─────────────────────────────────────────────────────────

class WrapdColors {
  WrapdColors._();

  // ── Grid & Spacing (8-pt Rule) ─────────────────────────
  static const double p4 = 4.0;
  static const double p2 = 2.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p48 = 48.0; // Row Height
  static const double p64 = 64.0;
  static const double p6 = 6.0; // Small UI element spacing
  static const double p3 = 3.0; // Minimal padding

  // ── Component Sizes ────────────────────────────────────
  static const double iconSizeMedium = 18.0; // Standard icon size
  static const double fontSizeMicro = 10.0;   // Micro text
  static const double fontSizeCaption = 11.0; // Caption text
  static const double fontSizeButton = 15.0;  // Button text
  static const double borderWidthMedium = 1.5; // Medium border stroke
  static const double lineWidth = 2.0;        // Standard line width
  static const double progressHeight = 5.0;   // Progress bar height

  // ── Speaker Dot Sizes ──────────────────────────────────
  static const double dotSizeSmall = 10.0;    // Small dot
  static const double dotSizeMedium = 12.0;   // Medium dot (default)
  static const double dotSizeLarger = 14.0;   // Larger dot
  static const double overlapSmall = 4.0;     // Small overlap
  static const double barHeight = 32.0;       // Standard bar height
  static const double barHeightTall = 24.0;   // Tall bar height

  // ── Border Radius ──────────────────────────────────────
  static const double radius = 12.0;
  static const double radiusHero = 16.0;
  static const double radiusSmall = 8.0;
  static const double radiusPill = 100.0;

  // ── Brand Colors ───────────────────────────────────────
  static const Color emerald = Color(0xFF00D97E);     // Confirmed / Done / Primary CTA
  static const Color emeraldDim = Color(0xFF00A862);  // Hover / light mode variant
  static const Color cobalt = Color(0xFF0A5CFF);      // Links / Secondary / Watermark
  static const Color cobaltDim = Color(0xFF0843CC);   // Cobalt hover/gradient variant
  static const Color amber = Color(0xFFFFB340);       // Needs confirmation
  static const Color rose = Color(0xFFFF4D6A);        // Stop / Danger / Error
  static const Color locked = Color(0xFF6B7280);      // Paywall / Disabled
  // Aliases for compatibility
  static const Color success = emerald;
  static const Color warning = amber;
  static const Color processing = amber;
  static const Color danger = rose;

  // ── Light Mode Surfaces ────────────────────────────────
  static const Color lightCanvas = Color(0xFFF4F5F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF111827);
  static const Color lightMuted = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE6E8EE);

  // ── Dark Mode Surfaces ─────────────────────────────────
  static const Color darkCanvas = Color(0xFF0C0D0F);
  static const Color darkVoid = Color(0xFF0C0D0F);
  static const Color darkInk = Color(0xFF13141A);
  static const Color darkSurface = Color(0xFF1C1D24);
  static const Color darkElevated = Color(0xFF24252E);
  static const Color darkLift = Color(0xFF24252E);
  static const Color darkBorder = Color(0xFF2E303C);
  static const Color darkText = Color(0xFFF2F3F8);
  static const Color darkMuted = Color(0xFF98989D);

  // ── Speaker Color Array ────────────────────────────────
  static const List<Color> speakers = [
    Color(0xFF2563EB), // S1 Blue
    Color(0xFF16A34A), // S2 Green
    Color(0xFF7C3AED), // S3 Purple
    Color(0xFFF59E0B), // S4 Amber
    Color(0xFFEF4444), // S5 Red
    Color(0xFF06B6D4), // S6 Cyan
  ];

  static Color getSpeakerColor(int index) =>
      speakers[index.abs() % speakers.length];

  // ── Animation Durations ────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  // ── Shadows ────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get heroShadow => [
        BoxShadow(
          color: cobalt.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

// ─────────────────────────────────────────────────────────
//  Theme Data Generator
// ─────────────────────────────────────────────────────────

class WrapdTheme {
  WrapdTheme._();

  static TextTheme _textTheme(Color bodyColor, Color displayColor) {
    final dmSans = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: bodyColor,
      displayColor: displayColor,
    );
    final syne = GoogleFonts.syne(
      fontWeight: FontWeight.w800,
      color: displayColor,
    );

    return dmSans.copyWith(
      headlineLarge: syne.copyWith(fontSize: 32, height: 1.25),
      headlineMedium: syne.copyWith(fontSize: 24, height: 1.33),
      titleLarge: syne.copyWith(fontSize: 20),
      // Body styles with DM Sans
      titleMedium: dmSans.titleMedium?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: bodyColor),
      titleSmall: dmSans.titleSmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: bodyColor),
      bodyLarge: dmSans.bodyLarge?.copyWith(
          fontSize: 16, height: 1.6, color: bodyColor),
      bodyMedium: dmSans.bodyMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w500, color: bodyColor),
      bodySmall: dmSans.bodySmall?.copyWith(
          fontSize: 12, color: bodyColor.withValues(alpha: 0.6)),
      labelLarge: dmSans.labelLarge?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: bodyColor),
    );
  }

  // ── Light Theme ───────────────────────────────────────
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: WrapdColors.lightCanvas,
        primaryColor: WrapdColors.cobalt,
        cardColor: WrapdColors.lightSurface,
        dividerColor: WrapdColors.lightBorder,
        textTheme: _textTheme(WrapdColors.lightText, WrapdColors.lightText),
        colorScheme: const ColorScheme.light(
          primary: WrapdColors.cobalt,
          secondary: WrapdColors.success,
          surface: WrapdColors.lightSurface,
          error: WrapdColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: WrapdColors.lightCanvas,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: WrapdColors.lightText),
          titleTextStyle: TextStyle(
              color: WrapdColors.lightText,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: WrapdColors.lightSurface,
          indicatorColor: WrapdColors.cobalt.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: WrapdColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(WrapdColors.radiusSmall),
            borderSide: const BorderSide(color: WrapdColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(WrapdColors.radiusSmall),
            borderSide: const BorderSide(color: WrapdColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(WrapdColors.radiusSmall),
            borderSide:
                const BorderSide(color: WrapdColors.cobalt, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WrapdColors.p16,
            vertical: WrapdColors.p12,
          ),
        ),
      );

  // ── Dark Theme ────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: WrapdColors.darkCanvas,
        primaryColor: WrapdColors.cobalt,
        cardColor: WrapdColors.darkSurface,
        dividerColor: WrapdColors.darkBorder,
        textTheme: _textTheme(WrapdColors.darkText, WrapdColors.darkText),
        colorScheme: const ColorScheme.dark(
          primary: WrapdColors.cobalt,
          secondary: WrapdColors.success,
          surface: WrapdColors.darkSurface,
          error: WrapdColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: WrapdColors.darkCanvas,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: WrapdColors.darkText),
          titleTextStyle: TextStyle(
              color: WrapdColors.darkText,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: WrapdColors.darkSurface,
          indicatorColor: WrapdColors.cobalt.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: WrapdColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(WrapdColors.radiusSmall),
            borderSide: const BorderSide(color: WrapdColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(WrapdColors.radiusSmall),
            borderSide: const BorderSide(color: WrapdColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(WrapdColors.radiusSmall),
            borderSide:
                const BorderSide(color: WrapdColors.cobalt, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: WrapdColors.p16,
            vertical: WrapdColors.p12,
          ),
        ),
      );
}

// Reusable navigation transition utility
class WrapdNavigator {
  static Route route(Widget screen) {
    return CupertinoPageRoute(builder: (_) => screen);
  }
}
