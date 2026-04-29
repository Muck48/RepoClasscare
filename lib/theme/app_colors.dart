import 'package:flutter/material.dart';

/// Unified Color System for ClassCare App
/// 
/// All colors are organized into semantic tokens that support both
/// light and dark modes. Use these instead of hardcoded Color(0xFF...).

class AppColors {
  AppColors._(); // Private constructor - use static members only

  // ─── SEMANTIC COLORS: PRIMARY ───────────────────────────────────────────

  /// Main brand red - used for primary actions, primary buttons, primary text
  static const Color primary = Color(0xFFB23A3A);
  static const Color primaryLight = Color(0xFFD46A6A); // Lighter shade
  static const Color primaryDark = Color(0xFF8B2D2D); // Darker shade

  // ─── SEMANTIC COLORS: HERO/ACCENT ───────────────────────────────────────

  /// Hero gradient top - for splash screens, hero sections
  static const Color heroGradientTop = Color(0xFFC24747);

  /// Hero gradient bottom - for splash screens, hero sections
  static const Color heroGradientBottom = Color(0xFF8D2D2D);

  // ─── SEMANTIC COLORS: BACKGROUND & SURFACES ────────────────────────────

  /// App background color (light theme)
  static const Color bgLight = Color(0xFFF8F8F8);

  /// App background color (dark theme)
  static const Color bgDark = Color(0xFF121212);

  /// Card/surface color (light theme)
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Card/surface color (dark theme)
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Secondary surface (light theme) - for elevated cards
  static const Color surfaceSecondaryLight = Color(0xFFFAFAFA);

  /// Secondary surface (dark theme)
  static const Color surfaceSecondaryDark = Color(0xFF2A2A2A);

  // ─── SEMANTIC COLORS: TEXT ──────────────────────────────────────────────

  /// Primary text color (light theme)
  static const Color textPrimaryLight = Color(0xFF242424);

  /// Primary text color (dark theme)
  static const Color textPrimaryDark = Color(0xFFEDEDED);

  /// Secondary text color (light theme) - for subtitles, hints
  static const Color textSecondaryLight = Color(0xFF6F6F6F);

  /// Secondary text color (dark theme)
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  /// Tertiary text color (light theme) - for disabled, very faint
  static const Color textTertiaryLight = Color(0xFF9E9E9E);

  /// Tertiary text color (dark theme)
  static const Color textTertiaryDark = Color(0xFF757575);

  // ─── SEMANTIC COLORS: BORDERS ───────────────────────────────────────────

  /// Border color (light theme)
  static const Color borderLight = Color(0xFFE9E9E9);

  /// Border color (dark theme)
  static const Color borderDark = Color(0xFF3A3A3A);

  /// Subtle border (light theme) - very light dividers
  static const Color borderSubtleLight = Color(0xFFF0F0F0);

  /// Subtle border (dark theme)
  static const Color borderSubtleDark = Color(0xFF2A2A2A);

  // ─── SEMANTIC COLORS: FORM FIELDS ───────────────────────────────────────

  /// Form field background (light theme)
  static const Color inputBgLight = Color(0xFFF7F7F7);

  /// Form field background (dark theme)
  static const Color inputBgDark = Color(0xFF2A2A2A);

  /// Form field border (light theme)
  static const Color inputBorderLight = Color(0xFFE1D5D5);

  /// Form field border (dark theme)
  static const Color inputBorderDark = Color(0xFF4A4A4A);

  /// Form field disabled (light theme)
  static const Color inputDisabledLight = Color(0xFFEDEDED);

  /// Form field disabled (dark theme)
  static const Color inputDisabledDark = Color(0xFF3A3A3A);

  // ─── SEMANTIC COLORS: BUTTONS ───────────────────────────────────────────

  /// Button background (light theme)
  static const Color buttonBgLight = Color(0xFFF7F2F2);

  /// Button background (dark theme)
  static const Color buttonBgDark = Color(0xFF2A2A2A);

  /// Button disabled (light theme)
  static const Color buttonDisabledLight = Color(0xFFEDEDED);

  /// Button disabled (dark theme)
  static const Color buttonDisabledDark = Color(0xFF3A3A3A);

  // ─── SEMANTIC COLORS: STATUS/ALERTS ─────────────────────────────────────

  /// Error/danger color
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFF5F2C2C);

  /// Success color
  static const Color success = Color(0xFF388E3C);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color successDark = Color(0xFF2E7D32);

  /// Warning color
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color warningDark = Color(0xFFE65100);

  /// Info color
  static const Color info = Color(0xFF1976D2);
  static const Color infoLight = Color(0xFFBBDEFB);
  static const Color infoDark = Color(0xFF1565C0);

  // ─── SEMANTIC COLORS: TINTS (for feature cards) ──────────────────────

  /// Tint for "Anonymous" feature card (light theme)
  static const Color tintAnonymousLight = Color(0xFFFFECEC);

  /// Tint for "Anonymous" feature card (dark theme)
  static const Color tintAnonymousDark = Color(0xFF3A2C2C);

  /// Tint for "Trackable" feature card (light theme)
  static const Color tintTrackableLight = Color(0xFFFFF1EC);

  /// Tint for "Trackable" feature card (dark theme)
  static const Color tintTrackableDark = Color(0xFF3A2E2A);

  /// Tint for "Secure" feature card (light theme)
  static const Color tintSecureLight = Color(0xFFFFF5E8);

  /// Tint for "Secure" feature card (dark theme)
  static const Color tintSecureDark = Color(0xFF3A3228);

  // ─── SEMANTIC COLORS: ICONS ─────────────────────────────────────────────

  /// Icon color (light theme)
  static const Color iconLight = Color(0xFF4B4B4B);

  /// Icon color (dark theme)
  static const Color iconDark = Color(0xFFCCCCCC);

  /// Icon active/focused (light theme)
  static const Color iconActiveLight = Color(0xFFB23A3A);

  /// Icon active/focused (dark theme)
  static const Color iconActiveDark = Color(0xFFFF6B6B);

  // ─── SEMANTIC COLORS: DIVIDERS & SEPARATORS ────────────────────────────

  /// Divider color (light theme)
  static const Color dividerLight = Color(0xFFD7D7D7);

  /// Divider color (dark theme)
  static const Color dividerDark = Color(0xFF3A3A3A);

  // ─── SEMANTIC COLORS: PROGRESS & LOADERS ───────────────────────────────

  /// Progress background (light theme)
  static const Color progressBgLight = Color(0xFFE8E1E1);

  /// Progress background (dark theme)
  static const Color progressBgDark = Color(0xFF3A3A3A);

  // ─── HELPER: GET COLOR BY THEME ─────────────────────────────────────────

  /// Get background color based on brightness
  static Color bgByTheme(Brightness brightness) =>
      brightness == Brightness.light ? bgLight : bgDark;

  /// Get surface color based on brightness
  static Color surfaceByTheme(Brightness brightness) =>
      brightness == Brightness.light ? surfaceLight : surfaceDark;

  /// Get primary text color based on brightness
  static Color textPrimaryByTheme(Brightness brightness) =>
      brightness == Brightness.light ? textPrimaryLight : textPrimaryDark;

  /// Get secondary text color based on brightness
  static Color textSecondaryByTheme(Brightness brightness) =>
      brightness == Brightness.light ? textSecondaryLight : textSecondaryDark;

  /// Get border color based on brightness
  static Color borderByTheme(Brightness brightness) =>
      brightness == Brightness.light ? borderLight : borderDark;

  /// Get input background based on brightness
  static Color inputBgByTheme(Brightness brightness) =>
      brightness == Brightness.light ? inputBgLight : inputBgDark;

  /// Get input border based on brightness
  static Color inputBorderByTheme(Brightness brightness) =>
      brightness == Brightness.light ? inputBorderLight : inputBorderDark;

  /// Get icon color based on brightness
  static Color iconByTheme(Brightness brightness) =>
      brightness == Brightness.light ? iconLight : iconDark;
}

/// Color palette for quick reference
class AppColorPalette {
  static final neutrals = {
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF5F5F5),
    200: Color(0xFFEDEDED),
    300: Color(0xFFE0E0E0),
    400: Color(0xFFBDBDBD),
    500: Color(0xFF9E9E9E),
    600: Color(0xFF757575),
    700: Color(0xFF616161),
    800: Color(0xFF424242),
    900: Color(0xFF212121),
  };

  static final reds = {
    50: Color(0xFFFFEBEE),
    100: Color(0xFFFFCDD2),
    200: Color(0xFFEF9A9A),
    300: Color(0xFFE57373),
    400: Color(0xFFEF5350),
    500: Color(0xFFF44336),
    600: Color(0xFFE53935),
    700: Color(0xFFD32F2F),
    800: Color(0xFFC62828),
    900: Color(0xFFB71C1C),
  };
}
