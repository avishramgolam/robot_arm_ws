import 'package:flutter/material.dart';

/// Central design system for the app.
///
/// Vibe: empathetic, modern, non-judgmental, "non-cringe".
/// Palette: soothing pastels — deep slate blue (primary), warm teal/mint
/// (secondary / positive), gentle lavender (tertiary / accents).
/// Deliberately avoids clinical whites, juvenile brights, and gendered themes.
abstract final class AppColors {
  // Brand
  static const slate = Color(0xFF3E5C76); // deep slate blue — primary
  static const slateDark = Color(0xFF2C4257);
  static const teal = Color(0xFF5FAE9C); // warm teal — secondary
  static const mint = Color(0xFFDCEFEA); // mint tint — chips, fills
  static const lavender = Color(0xFFA99FCC); // gentle lavender — tertiary
  static const lavenderTint = Color(0xFFEDEAF6);

  // Surfaces & text
  static const background = Color(0xFFF7F6F3); // warm off-white, not clinical
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2A2D34); // near-black body text
  static const inkMuted = Color(0xFF6B7280);

  // Semantic
  static const mythRose = Color(0xFFC98A98); // muted rose for "Myth" cards
  static const factTeal = teal; //             teal for "Fact" cards
  static const verifiedBadge = Color(0xFF4C8577); // RAG "verified" badges
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.slate,
      primary: AppColors.slate,
      secondary: AppColors.teal,
      tertiary: AppColors.lavender,
      surface: AppColors.surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.background,

      // System font stack keeps the app fully offline (no runtime font
      // fetching) and feels native on each platform.
      fontFamily: null,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
        bodyLarge: TextStyle(color: AppColors.ink, height: 1.45),
        bodyMedium: TextStyle(color: AppColors.ink, height: 1.4),
        labelMedium: TextStyle(color: AppColors.inkMuted),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.3,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.mint,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: AppColors.slateDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.lavenderTint,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
      ),
    );
  }
}
