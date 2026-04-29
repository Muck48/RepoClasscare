import 'package:flutter/material.dart';

/// Unified Spacing & Border Radius System for ClassCare App
/// 
/// Defines consistent spacing, padding, margins, and border radius
/// values across the entire app.

class AppSpacing {
  AppSpacing._(); // Private constructor - use static members only

  // ─── SPACING SCALE (STANDARD) ───────────────────────────────────────────
  // Based on 4px baseline, multiples create visual rhythm

  /// 4px - minimum spacing, dense UI elements
  static const double xs = 4.0;

  /// 8px - small spacing, adjacent elements
  static const double sm = 8.0;

  /// 12px - medium-small spacing, related elements
  static const double md = 12.0;

  /// 16px - medium spacing, standard padding/margin
  static const double lg = 16.0;

  /// 20px - medium-large spacing, section separation
  static const double xl = 20.0;

  /// 24px - large spacing, major section separation
  static const double xxl = 24.0;

  /// 32px - extra large spacing, page sections
  static const double xxxl = 32.0;

  /// 40px - maximum spacing, major page divisions
  static const double huge = 40.0;

  // ─── PADDING SHORTCUTS ──────────────────────────────────────────────────

  /// All sides: 4px
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);

  /// All sides: 8px
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);

  /// All sides: 12px
  static const EdgeInsets paddingMd = EdgeInsets.all(md);

  /// All sides: 16px
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  /// All sides: 20px
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  /// All sides: 24px
  static const EdgeInsets paddingXxl = EdgeInsets.all(xxl);

  /// Horizontal: 16px, Vertical: 12px (standard button)
  static const EdgeInsets paddingButton =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);

  /// Horizontal: 16px, Vertical: 16px (card content)
  static const EdgeInsets paddingCard = EdgeInsets.all(lg);

  /// Horizontal: 20px, Vertical: 24px (page content)
  static const EdgeInsets paddingPage = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: xxl,
  );

  // ─── MARGIN SHORTCUTS ───────────────────────────────────────────────────

  /// All sides: 4px
  static const EdgeInsets marginXs = EdgeInsets.all(xs);

  /// All sides: 8px
  static const EdgeInsets marginSm = EdgeInsets.all(sm);

  /// All sides: 12px
  static const EdgeInsets marginMd = EdgeInsets.all(md);

  /// All sides: 16px
  static const EdgeInsets marginLg = EdgeInsets.all(lg);

  /// All sides: 20px
  static const EdgeInsets marginXl = EdgeInsets.all(xl);

  /// Bottom: 16px (standard element margin)
  static const EdgeInsets marginBottom = EdgeInsets.only(bottom: lg);

  /// Top: 16px
  static const EdgeInsets marginTop = EdgeInsets.only(top: lg);

  // ─── GAP/SPACING BETWEEN ITEMS ──────────────────────────────────────────

  /// 4px gap between items
  static const double gapXs = xs;

  /// 8px gap between items (dense lists)
  static const double gapSm = sm;

  /// 12px gap between items (standard)
  static const double gapMd = md;

  /// 16px gap between items (relaxed)
  static const double gapLg = lg;

  /// 24px gap between items (sections)
  static const double gapXxl = xxl;
}

/// Border Radius System for ClassCare App
/// 
/// Consistent border radius values across the app.

class AppBorderRadius {
  AppBorderRadius._(); // Private constructor - use static members only

  // ─── BORDER RADIUS SCALE ────────────────────────────────────────────────
  // Named scale: XS, SM, MD, LG, XL, FULL

  /// Extra small border radius: 4px (subtle)
  static const double xs = 4.0;

  /// Small border radius: 8px (tight radius)
  static const double sm = 8.0;

  /// Medium border radius: 12px (standard)
  static const double md = 12.0;

  /// Medium-Large border radius: 16px (more rounded)
  static const double lg = 16.0;

  /// Large border radius: 20px (significant roundness)
  static const double xl = 20.0;

  /// Extra large border radius: 24px (very rounded)
  static const double xxl = 24.0;

  /// Full/Pill radius: 999px (fully rounded)
  static const double full = 999.0;

  // ─── BORDER RADIUS SHORTCUTS ────────────────────────────────────────────

  /// BorderRadius: all sides 4px
  static final BorderRadius radiusXs = BorderRadius.circular(xs);

  /// BorderRadius: all sides 8px
  static final BorderRadius radiusSm = BorderRadius.circular(sm);

  /// BorderRadius: all sides 12px
  static final BorderRadius radiusMd = BorderRadius.circular(md);

  /// BorderRadius: all sides 16px
  static final BorderRadius radiusLg = BorderRadius.circular(lg);

  /// BorderRadius: all sides 20px
  static final BorderRadius radiusXl = BorderRadius.circular(xl);

  /// BorderRadius: all sides 24px
  static final BorderRadius radiusXxl = BorderRadius.circular(xxl);

  /// BorderRadius: fully rounded (pill shape)
  static final BorderRadius radiusFull = BorderRadius.circular(full);

  // ─── BORDER RADIUS: ONLY CORNERS ────────────────────────────────────────

  /// Only top corners: 24px
  static final BorderRadius radiusTopXxl =
      BorderRadius.vertical(top: Radius.circular(xxl));

  /// Only bottom corners: 24px
  static final BorderRadius radiusBottomXxl =
      BorderRadius.vertical(bottom: Radius.circular(xxl));

  /// Only top-left: 16px
  static final BorderRadius radiusTopLeftLg =
      BorderRadius.only(topLeft: Radius.circular(lg));

  /// Only top-right: 16px
  static final BorderRadius radiusTopRightLg =
      BorderRadius.only(topRight: Radius.circular(lg));

  /// Only bottom-left: 16px
  static final BorderRadius radiusBottomLeftLg =
      BorderRadius.only(bottomLeft: Radius.circular(lg));

  /// Only bottom-right: 16px
  static final BorderRadius radiusBottomRightLg =
      BorderRadius.only(bottomRight: Radius.circular(lg));

  // ─── SHAPE SHORTCUTS ────────────────────────────────────────────────────

  /// Rounded rectangle: 12px
  static RoundedRectangleBorder rectMd({Color? side}) =>
      RoundedRectangleBorder(
        borderRadius: radiusMd,
        side: BorderSide(color: side ?? Colors.transparent),
      );

  /// Rounded rectangle: 16px
  static RoundedRectangleBorder rectLg({Color? side}) =>
      RoundedRectangleBorder(
        borderRadius: radiusLg,
        side: BorderSide(color: side ?? Colors.transparent),
      );

  /// Pill/Fully rounded rectangle
  static RoundedRectangleBorder rectFull({Color? side}) =>
      RoundedRectangleBorder(
        borderRadius: radiusFull,
        side: BorderSide(color: side ?? Colors.transparent),
      );
}

/// Size/Dimension System for ClassCare App
class AppSizes {
  AppSizes._(); // Private constructor - use static members only

  // ─── ICON SIZES ──────────────────────────────────────────────────────────

  /// Small icon: 16px
  static const double iconSm = 16.0;

  /// Standard icon: 24px
  static const double iconMd = 24.0;

  /// Large icon: 32px
  static const double iconLg = 32.0;

  /// Extra large icon: 48px
  static const double iconXl = 48.0;

  // ─── BUTTON HEIGHTS ─────────────────────────────────────────────────────

  /// Dense button: 36px
  static const double buttonHeightSm = 36.0;

  /// Standard button: 44px
  static const double buttonHeightMd = 44.0;

  /// Large button: 52px
  static const double buttonHeightLg = 52.0;

  // ─── INPUT FIELD HEIGHTS ─────────────────────────────────────────────────

  /// Standard input: 44px
  static const double inputHeight = 44.0;

  /// Dense input: 36px
  static const double inputHeightDense = 36.0;

  /// Large input: 52px
  static const double inputHeightLarge = 52.0;

  // ─── CARD SIZES ──────────────────────────────────────────────────────────

  /// Minimum card width
  static const double cardMinWidth = 160.0;

  /// Standard card width
  static const double cardWidth = 280.0;

  /// Maximum card width
  static const double cardMaxWidth = 400.0;

  // ─── AVATAR SIZES ───────────────────────────────────────────────────────

  /// Avatar XS: 24px
  static const double avatarXs = 24.0;

  /// Avatar SM: 32px
  static const double avatarSm = 32.0;

  /// Avatar MD: 48px
  static const double avatarMd = 48.0;

  /// Avatar LG: 64px
  static const double avatarLg = 64.0;

  /// Avatar XL: 96px
  static const double avatarXl = 96.0;
}
