import 'package:flutter/material.dart';

/// Centralized design system for Indigi Attendance
/// Professional, enterprise-grade aesthetic with a clean, minimal palette.
class AppTheme {
  AppTheme._();

  // ─── Core Palette ──────────────────────────────────────────────────────────

  /// Deep navy — used for primary actions and accents
  static const Color primary = Color(0xFF1A237E);

  /// Bright indigo — used as the lighter accent
  static const Color accent = Color(0xFF3D5AFE);

  /// Subtle indigo tint — backgrounds, chips
  static const Color accentLight = Color(0xFFEEF0FF);

  /// Success green
  static const Color success = Color(0xFF00897B);
  static const Color successLight = Color(0xFFE0F2F1);

  /// Warning amber
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  /// Error red
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);

  // ─── Neutral Palette ───────────────────────────────────────────────────────

  /// Page backgrounds
  static const Color background = Color(0xFFF7F8FC);

  /// Card / surface
  static const Color surface = Colors.white;

  /// Primary text
  static const Color textPrimary = Color(0xFF111827);

  /// Secondary text
  static const Color textSecondary = Color(0xFF6B7280);

  /// Subtle tertiary text / labels
  static const Color textTertiary = Color(0xFF9CA3AF);

  /// Thin dividers / borders
  static const Color border = Color(0xFFE5E7EB);

  /// Hover / selected surface
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // ─── Shadows ───────────────────────────────────────────────────────────────

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x04000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> accentShadow = [
    BoxShadow(
      color: accent.withValues(alpha: 0.28),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> successShadow = [
    BoxShadow(
      color: success.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ─── Border Radius ─────────────────────────────────────────────────────────

  static const BorderRadius radiusXS = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusXXL = BorderRadius.all(Radius.circular(32));

  // ─── MaterialApp ThemeData ─────────────────────────────────────────────────

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        primary: accent,
        secondary: primary,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radiusXL,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: radiusMD),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: radiusMD,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMD,
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMD,
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMD,
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: accent, fontSize: 12),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ─── Common Text Styles ────────────────────────────────────────────────────

  static const TextStyle headingXL = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -0.8,
    height: 1.2,
  );

  static const TextStyle headingLG = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.6,
    height: 1.25,
  );

  static const TextStyle headingMD = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
    height: 1.3,
  );

  static const TextStyle headingSM = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyLG = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle bodyMD = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodySM = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textTertiary,
    letterSpacing: 0.8,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  // ─── Section Header ────────────────────────────────────────────────────────

  static Widget sectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title.toUpperCase(), style: label),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ─── Status Badge ──────────────────────────────────────────────────────────

  static Widget statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: radiusXS,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─── Icon Container ────────────────────────────────────────────────────────

  static Widget iconContainer({
    required IconData icon,
    required Color color,
    double size = 20,
    double padding = 10,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: radiusSM,
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
