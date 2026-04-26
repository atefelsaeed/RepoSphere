import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const primary = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);

  // Dark theme surfaces
  static const darkBg = Color(0xFF070B14);
  static const darkSurface = Color(0xFF0D1321);
  static const darkCard = Color(0xFF111827);
  static const darkBorder = Color(0xFF1F2937);
  static const darkMuted = Color(0xFF6B7280);

  // Light theme surfaces
  static const lightBg = Color(0xFFF8FAFC);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightMuted = Color(0xFF64748B);

  // Semantic
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const merged = Color(0xFFA371F7);
}

class AppTheme {
  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? const Color(0xFFF9FAFB)
        : const Color(0xFF0F172A);
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(color: base, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.inter(color: base, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.inter(color: base, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.inter(color: base, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(color: base, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(color: base, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(color: base, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.inter(color: base),
      bodyMedium: GoogleFonts.inter(color: base),
      bodySmall: GoogleFonts.inter(color: base.withAlpha(180)),
      labelLarge: GoogleFonts.inter(color: base, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.inter(color: base.withAlpha(200)),
      labelSmall: GoogleFonts.inter(color: base.withAlpha(180)),
    );
  }

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryLight,
          onPrimary: Colors.white,
          secondary: const Color(0xFF06B6D4),
          onSecondary: Colors.white,
          surface: AppColors.darkCard,
          onSurface: const Color(0xFFF9FAFB),
          onSurfaceVariant: AppColors.darkMuted,
          outline: AppColors.darkBorder,
          outlineVariant: AppColors.darkBorder,
          error: AppColors.error,
          primaryContainer: AppColors.primary.withAlpha(40),
          onPrimaryContainer: AppColors.primaryLight,
          surfaceContainerHighest: AppColors.darkSurface,
          surfaceContainerLow: AppColors.darkCard,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        textTheme: _textTheme(Brightness.dark),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.darkBorder),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: const Color(0xFFF9FAFB),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: const Color(0xFFF9FAFB),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          surfaceTintColor: Colors.transparent,
          shape: const Border(
            bottom: BorderSide(color: AppColors.darkBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: AppColors.darkMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedColor: AppColors.primary.withAlpha(60),
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: GoogleFonts.inter(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
          space: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.darkMuted,
          indicatorColor: AppColors.primaryLight,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(),
          dividerColor: AppColors.darkBorder,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: const Color(0xFF0891B2),
          onSecondary: Colors.white,
          surface: AppColors.lightCard,
          onSurface: const Color(0xFF0F172A),
          onSurfaceVariant: AppColors.lightMuted,
          outline: AppColors.lightBorder,
          outlineVariant: AppColors.lightBorder,
          error: AppColors.error,
          primaryContainer: AppColors.primary.withAlpha(20),
          onPrimaryContainer: AppColors.primary,
          surfaceContainerHighest: AppColors.lightBg,
          surfaceContainerLow: AppColors.lightCard,
        ),
        scaffoldBackgroundColor: AppColors.lightBg,
        textTheme: _textTheme(Brightness.light),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.lightBorder),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightCard,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          surfaceTintColor: Colors.transparent,
          shape: const Border(
            bottom: BorderSide(color: AppColors.lightBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: AppColors.lightMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.lightBg,
          selectedColor: AppColors.primary.withAlpha(20),
          side: const BorderSide(color: AppColors.lightBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: GoogleFonts.inter(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightBorder,
          thickness: 1,
          space: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.lightMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(),
          dividerColor: AppColors.lightBorder,
        ),
      );
}
