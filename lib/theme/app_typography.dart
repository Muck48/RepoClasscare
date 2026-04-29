import 'package:flutter/material.dart';

/// Unified Typography System for ClassCare App
/// 
/// Defines all text styles used throughout the app to ensure
/// consistency in typography. Use TextStyle from here instead of
/// hardcoding font properties.

class AppTypography {
  AppTypography._(); // Private constructor - use static members only

  // ─── FONT FAMILIES ──────────────────────────────────────────────────────

  /// Primary font family (default: system font)
  static const String fontFamilyDefault = 'Roboto';

  // ─── FONT WEIGHTS (STANDARDIZED) ────────────────────────────────────────
  /// Use these instead of FontWeight.w500, FontWeight.w700, etc.

  /// Regular weight - 400 (body text)
  static const FontWeight weightRegular = FontWeight.w400;

  /// Medium weight - 500 (body text, some labels)
  static const FontWeight weightMedium = FontWeight.w500;

  /// Semi-bold weight - 600 (button text, some headings)
  static const FontWeight weightSemiBold = FontWeight.w600;

  /// Bold weight - 700 (headings, emphasis, labels)
  static const FontWeight weightBold = FontWeight.w700;

  /// Extra-bold weight - 800 (prominent headings, hero text)
  static const FontWeight weightExtraBold = FontWeight.w800;

  /// Black weight - 900 (maximum emphasis, large displays)
  static const FontWeight weightBlack = FontWeight.w900;

  // ─── DISPLAY / HERO TEXT ────────────────────────────────────────────────

  /// Hero/Display text: 40px, ExtraBold (used in splash, major headings)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 40,
    fontWeight: weightExtraBold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Display text: 32px, Bold (main headings)
  static const TextStyle displayMedium = TextStyle(
    fontSize: 32,
    fontWeight: weightBold,
    height: 1.25,
    letterSpacing: -0.25,
  );

  /// Display text: 24px, Bold (major section headings)
  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: weightBold,
    height: 1.3,
    letterSpacing: 0,
  );

  // ─── HEADINGS ───────────────────────────────────────────────────────────

  /// Heading 1: 28px, Bold (page titles, major headings)
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: weightBold,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Heading 2: 24px, Bold (section headings)
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: weightBold,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Heading 3: 20px, Bold (subsection headings)
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: weightBold,
    height: 1.35,
    letterSpacing: 0,
  );

  /// Heading 4: 18px, SemiBold (card titles, form labels)
  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: weightSemiBold,
    height: 1.35,
    letterSpacing: 0.15,
  );

  /// Heading 5: 16px, SemiBold (medium labels)
  static const TextStyle heading5 = TextStyle(
    fontSize: 16,
    fontWeight: weightSemiBold,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Heading 6: 14px, SemiBold (small labels)
  static const TextStyle heading6 = TextStyle(
    fontSize: 14,
    fontWeight: weightSemiBold,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // ─── BODY TEXT ───────────────────────────────────────────────────────────

  /// Body large: 16px, Regular (main body text)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: weightRegular,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Body large bold: 16px, Bold (emphasized body text)
  static const TextStyle bodyLargeBold = TextStyle(
    fontSize: 16,
    fontWeight: weightBold,
    height: 1.5,
    letterSpacing: 0.15,
  );

  /// Body medium: 14px, Regular (standard body text)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: weightRegular,
    height: 1.5,
    letterSpacing: 0.25,
  );

  /// Body medium bold: 14px, Bold (emphasized body text)
  static const TextStyle bodyMediumBold = TextStyle(
    fontSize: 14,
    fontWeight: weightBold,
    height: 1.5,
    letterSpacing: 0.25,
  );

  /// Body small: 12px, Regular (captions, helper text)
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: weightRegular,
    height: 1.5,
    letterSpacing: 0.4,
  );

  /// Body small bold: 12px, Bold (emphasized small text)
  static const TextStyle bodySmallBold = TextStyle(
    fontSize: 12,
    fontWeight: weightBold,
    height: 1.5,
    letterSpacing: 0.4,
  );

  // ─── LABELS & BUTTONS ───────────────────────────────────────────────────

  /// Button large: 16px, Bold (primary button text)
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: weightBold,
    height: 1.5,
    letterSpacing: 0.5,
  );

  /// Button medium: 14px, Bold (standard button text)
  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: weightBold,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Button small: 12px, SemiBold (small button text)
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: weightSemiBold,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ─── LABELS ─────────────────────────────────────────────────────────────

  /// Label large: 16px, Medium (form labels, badges)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: weightMedium,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Label medium: 14px, Medium (standard labels)
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: weightMedium,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Label small: 12px, Medium (small labels, tags)
  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: weightMedium,
    height: 1.3,
    letterSpacing: 0.5,
  );

  /// Label extra small: 11px, Medium (tiny labels, micro-text)
  static const TextStyle labelXSmall = TextStyle(
    fontSize: 11,
    fontWeight: weightMedium,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ─── CAPTIONS & HELPER TEXT ─────────────────────────────────────────────

  /// Caption large: 14px, Regular (captions, subtitles)
  static const TextStyle captionLarge = TextStyle(
    fontSize: 14,
    fontWeight: weightRegular,
    height: 1.4,
    letterSpacing: 0.25,
  );

  /// Caption medium: 12px, Regular (standard captions)
  static const TextStyle captionMedium = TextStyle(
    fontSize: 12,
    fontWeight: weightRegular,
    height: 1.35,
    letterSpacing: 0.4,
  );

  /// Caption small: 11px, Regular (small captions, metadata)
  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: weightRegular,
    height: 1.3,
    letterSpacing: 0.5,
  );

  // ─── OVERLINE (ALL-CAPS LABELS) ──────────────────────────────────────────

  /// Overline large: 14px, SemiBold, all-caps
  static const TextStyle overlineLarge = TextStyle(
    fontSize: 14,
    fontWeight: weightSemiBold,
    height: 1.3,
    letterSpacing: 1.0,
  );

  /// Overline medium: 12px, SemiBold, all-caps
  static const TextStyle overlineMedium = TextStyle(
    fontSize: 12,
    fontWeight: weightSemiBold,
    height: 1.3,
    letterSpacing: 0.8,
  );

  /// Overline small: 11px, SemiBold, all-caps
  static const TextStyle overlineSmall = TextStyle(
    fontSize: 11,
    fontWeight: weightSemiBold,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // ─── SPECIAL PURPOSE ─────────────────────────────────────────────────────

  /// Error message: 14px, Regular, red
  static TextStyle errorText(Color color) => TextStyle(
    fontSize: 14,
    fontWeight: weightRegular,
    height: 1.4,
    color: color,
  );

  /// Success message: 14px, Regular, green
  static TextStyle successText(Color color) => TextStyle(
    fontSize: 14,
    fontWeight: weightRegular,
    height: 1.4,
    color: color,
  );

  /// Hint text: 14px, Regular, secondary color
  static TextStyle hintText(Color color) => TextStyle(
    fontSize: 14,
    fontWeight: weightRegular,
    height: 1.4,
    color: color,
  );

  /// Code/monospace: 12px, Regular
  static const TextStyle code = TextStyle(
    fontSize: 12,
    fontWeight: weightRegular,
    fontFamily: 'Courier',
    height: 1.4,
    letterSpacing: 0.5,
  );
}
