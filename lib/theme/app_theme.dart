import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Apple Luxury / iOS Native Design Tokens ─────────────────────────────────
class AppColors {
  // Brand Primary – Apple Refined Emerald
  static const Color emerald = Color(0xFF059669);
  static const Color emeraldLight = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF047857);
  static const Color emeraldSurface = Color(0xFFECFDF5);

  // Backward compatibility aliases
  static const Color coral = emerald;
  static const Color coralLight = emeraldLight;
  static const Color coralDark = emeraldDark;

  // Graphite / Slate
  static const Color slate = Color(0xFF1C1C1E); // Apple system dark label
  static const Color slateLight = Color(0xFF2C2C2E);
  static const Color slateSurface = Color(0xFF3A3A3C);

  // Backward compatibility aliases
  static const Color charcoal = slate;
  static const Color charcoalLight = slateLight;
  static const Color charcoalSurface = slateSurface;

  // iOS System Accents
  static const Color blueAccent = Color(0xFF007AFF);
  static const Color tealAccent = Color(0xFF30B0C7);
  static const Color amberAccent = Color(0xFFFF9500);
  static const Color purpleAccent = Color(0xFF5856D6);
  static const Color pinkAccent = Color(0xFFFF2D55);

  // iOS Canvas & Surfaces
  static const Color background = Color(0xFFF2F2F7); // Apple system grouped background
  static const Color surface = Color(0xFFFFFFFF); // Pure white card
  static const Color surfaceSecondary = Color(0xFFE5E5EA); // Hairline divider / fill
  static const Color surfaceTertiary = Color(0xFFF2F2F7);
  static const Color cardBorder = Color(0xFFE5E5EA); // Hairline 0.8px border

  // Status & Accent Aliases
  static const Color amber = Color(0xFFFF9500); // Apple amber

  // iOS Hierarchy Typography
  static const Color textPrimary = Color(0xFF1C1C1E); // Primary Label
  static const Color textSecondary = Color(0xFF8E8E93); // Secondary Label
  static const Color textTertiary = Color(0xFFC7C7CC); // Tertiary Label
  static const Color textHint = Color(0xFFAEAEC2);

  // Status Colors (Apple HIG)
  static const Color success = Color(0xFF34C759); // Apple system green
  static const Color warning = Color(0xFFFF9500); // Apple system orange
  static const Color error = Color(0xFFFF3B30); // Apple system red
  static const Color info = Color(0xFF007AFF); // Apple system blue

  // iOS Native Tab Bar
  static const Color navBackground = Color(0xEBFFFFFF); // 92% translucent white
  static const Color navBorder = Color(0x38000000); // 0.5px hairline divider
  static const Color navItemInactive = Color(0xFF8E8E93); // iOS muted grey
  static const Color navItemActive = Color(0xFF059669); // Emerald active tint
}

// ─── Apple Typography ────────────────────────────────────────────────────────
class AppText {
  static const String fontFamily = 'SF Pro Display';

  // Large Title (34pt / bold / -0.8 tracking)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 1.15,
  );

  // Title 1 (28pt / bold / -0.6 tracking)
  static const TextStyle displayMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // Title 2 (22pt / bold / -0.4 tracking)
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  // Title 3 / Headline (18pt / semi-bold / -0.2 tracking)
  static const TextStyle headingMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Body (16pt / regular / -0.1 tracking)
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
    height: 1.45,
  );

  // Subheadline / Callout (14pt / regular)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  // Caption (11pt / medium / +0.1 tracking)
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  // Section Header (12pt / uppercase / bold / +0.8 tracking)
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );
}

// ─── Spacing ─────────────────────────────────────────────────────────────────
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;
}

// ─── Radius ─────────────────────────────────────────────────────────────────
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // Standard iOS card radius
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
}

// ─── Shadows (Apple Soft Ambient Depth) ──────────────────────────────────────
class AppShadows {
  // Delicate card shadow with zero harsh edges
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.02),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get emerald => [
    BoxShadow(
      color: AppColors.emerald.withValues(alpha: 0.25),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get coral => emerald;

  // Native tab bar subtle upward blur
  static List<BoxShadow> get navbar => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, -3),
    ),
  ];
}

// ─── Theme ───────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.emerald,
        primary: AppColors.emerald,
        secondary: AppColors.slate,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Color(0xFFE5E5EA), width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 0.8),
        ),
        labelStyle: AppText.bodySmall,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        backgroundColor: AppColors.slate,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E5EA),
        thickness: 0.6,
        space: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.emerald,
      ),
    );
  }
}

// ─── Subtle Refined Accents (Zero Tacky Gradients) ───────────────────────────
class AppGradients {
  // Understated monochrome hero
  static const LinearGradient slate = LinearGradient(
    colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient charcoal = slate;

  static const LinearGradient emerald = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coral = emerald;

  // Clean, quiet hero header
  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient success = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF047857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warning = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
