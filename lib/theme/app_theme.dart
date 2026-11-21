import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors (EcoTahu Design Tokens)
  static const Color primaryGreen = Color(0xFF059669); // Emerald 600
  static const Color emeraldDark = Color(0xFF047857);  // Emerald 700
  static const Color emeraldLight = Color(0xFF34D399); // Emerald 400 (High-contrast on dark)
  static const Color emeraldBright = Color(0xFF6EE7B7); // Emerald 300 (Crisp badge/pill text on dark)
  static const Color emeraldVivid = Color(0xFF10B981); // Emerald 500 (Vivid solid button on dark)
  static const Color emeraldSoft = Color(0xFFD1FAE5);  // Emerald 100
  static const Color emeraldDarkSoft = Color(0xFF064E3B);

  static const Color accentAmber = Color(0xFFD97706);  // Amber 600
  static const Color accentLight = Color(0xFFFBBF24);  // Amber 400
  static const Color amberBright = Color(0xFFFCD34D);  // Amber 300 (High-contrast amber on dark)
  static const Color accentSoft = Color(0xFFFEF3C7);   // Amber 100

  // Danger / Info
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color dangerDarkSoft = Color(0xFF7F1D1D);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoSoft = Color(0xFFDBEAFE);

  // Light Mode Tokens
  static const Color lightScaffold = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSoft = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Dark Mode Tokens (Matches Web Dark Theme)
  static const Color darkScaffold = Color(0xFF020617);        // Slate 950
  static const Color darkSurface = Color(0xFF1E293B);         // Slate 800
  static const Color darkSurfaceElevated = Color(0xFF334155); // Slate 700
  static const Color darkBorder = Color(0xFF334155);          // Slate 700
  static const Color darkBorderSoft = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);   // Slate 300 (Higher contrast on dark)
  static const Color darkTextMuted = Color(0xFF94A3B8);       // Slate 400 (Higher contrast hint on dark)

  // Backward compatibility constants
  static const Color darkGreen = Color(0xFF1A3C34);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color creamBg = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textBlack = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);

  // Dynamic Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? darkScaffold : lightScaffold;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color surfaceElevated(BuildContext context) =>
      isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : lightTextMuted;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  // ThemeData Builder
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightScaffold,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentAmber,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: danger,
      ),
      cardColor: lightSurface,
      dividerColor: lightBorder,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightScaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightTextPrimary,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: emeraldLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: lightTextSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        hintStyle: const TextStyle(color: lightTextMuted, fontSize: 14),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkScaffold,
      primaryColor: emeraldLight,
      colorScheme: const ColorScheme.dark(
        primary: emeraldLight,
        secondary: amberBright,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: danger,
      ),
      cardColor: darkSurface,
      dividerColor: darkBorder,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkScaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.3,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: emeraldLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF475569)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: emeraldLight,
        unselectedItemColor: darkTextSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: emeraldLight, width: 2),
        ),
        hintStyle: const TextStyle(color: darkTextMuted, fontSize: 14),
      ),
    );
  }
}

// Convenient BuildContext extension for concise code
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get scaffoldBg => AppTheme.scaffoldBg(this);
  Color get surface => AppTheme.surface(this);
  Color get surfaceElevated => AppTheme.surfaceElevated(this);
  Color get cardBg => AppTheme.cardBg(this);
  Color get border => AppTheme.border(this);
  Color get textPrimary => AppTheme.textPrimary(this);
  Color get textSecondary => AppTheme.textSecondary(this);
  Color get textMuted => AppTheme.textMuted(this);

  Color get brandGreen => isDark ? AppTheme.emeraldLight : AppTheme.primaryGreen;
  Color get brandGreenBright => isDark ? AppTheme.emeraldBright : AppTheme.emeraldDark;
  Color get brandGreenSolid => isDark ? AppTheme.emeraldVivid : AppTheme.primaryGreen;
  Color get brandAmber => isDark ? AppTheme.amberBright : AppTheme.accentAmber;

  Color get tahuTagBg =>
      isDark ? const Color(0xFF10B981).withValues(alpha: 0.20) : const Color(0xFFECFDF5);
  Color get tahuTagBorder =>
      isDark ? const Color(0xFF34D399).withValues(alpha: 0.45) : const Color(0xFFA7F3D0);
  Color get tahuTagText => isDark ? AppTheme.emeraldBright : const Color(0xFF047857);

  Color get limbahTagBg =>
      isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.20) : const Color(0xFFFFFBEB);
  Color get limbahTagBorder =>
      isDark ? const Color(0xFFFBBF24).withValues(alpha: 0.45) : const Color(0xFFFDE68A);
  Color get limbahTagText => isDark ? AppTheme.amberBright : const Color(0xFFB45309);

  Color get glassBg => isDark
      ? const Color(0xFF1E293B).withValues(alpha: 0.90)
      : Colors.white.withValues(alpha: 0.92);
  Color get glassBorder => isDark
      ? const Color(0xFF475569).withValues(alpha: 0.70)
      : Colors.white.withValues(alpha: 0.85);
}
