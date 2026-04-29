# ClassCare Design System - Design Tokens

Complete design system with unified colors, typography, spacing, and border radius for visual consistency.

## 📦 What's Included

### 1. **AppColors** (`app_colors.dart`)
Unified color system with light and dark mode support.

**Core Colors:**
- `AppColors.primary` - Brand red (#B23A3A)
- `AppColors.heroGradientTop` - Splash top color (#C24747)
- `AppColors.heroGradientBottom` - Splash bottom color (#8D2D2D)

**Theme-Aware Colors:**
- `AppColors.bgLight` / `AppColors.bgDark` - Background
- `AppColors.surfaceLight` / `AppColors.surfaceDark` - Cards
- `AppColors.textPrimaryLight` / `AppColors.textPrimaryDark` - Body text
- `AppColors.textSecondaryLight` / `AppColors.textSecondaryDark` - Subtitles
- `AppColors.borderLight` / `AppColors.borderDark` - Dividers

**Status Colors:**
- `AppColors.error`, `AppColors.success`, `AppColors.warning`, `AppColors.info`

**Helper Methods:**
```dart
AppColors.bgByTheme(brightness)        // Get BG by theme
AppColors.textPrimaryByTheme(brightness) // Get text color by theme
AppColors.borderByTheme(brightness)    // Get border by theme
```

### 2. **AppTypography** (`app_typography.dart`)
Standardized text styles and font weights.

**Font Weights (Normalized):**
- `AppTypography.weightRegular` - 400 (body)
- `AppTypography.weightMedium` - 500 (labels)
- `AppTypography.weightSemiBold` - 600 (buttons)
- `AppTypography.weightBold` - 700 (headings)
- `AppTypography.weightExtraBold` - 800 (prominent)
- `AppTypography.weightBlack` - 900 (maximum)

**Text Scales:**
- **Display:** `displayLarge` (40px), `displayMedium` (32px), `displaySmall` (24px)
- **Headings:** `heading1` (28px) to `heading6` (14px)
- **Body:** `bodyLarge` (16px), `bodyMedium` (14px), `bodySmall` (12px)
- **Labels:** `labelLarge` (16px), `labelMedium` (14px), `labelSmall` (12px)
- **Buttons:** `buttonLarge` (16px), `buttonMedium` (14px), `buttonSmall` (12px)
- **Captions:** `captionLarge` (14px), `captionMedium` (12px), `captionSmall` (11px)

### 3. **AppSpacing** (`app_spacing.dart`)
Consistent spacing scale for padding, margins, and gaps.

**Spacing Scale:**
- `xs` = 4px (minimum)
- `sm` = 8px (small)
- `md` = 12px (medium-small)
- `lg` = 16px (standard)
- `xl` = 20px (medium-large)
- `xxl` = 24px (large)
- `xxxl` = 32px (extra-large)
- `huge` = 40px (maximum)

**Pre-configured Padding:**
- `paddingXs`, `paddingSm`, `paddingMd`, `paddingLg`, `paddingXl`, `paddingXxl`
- `paddingButton` - 16px horizontal, 12px vertical
- `paddingCard` - 16px all sides
- `paddingPage` - 20px horizontal, 24px vertical

### 4. **AppBorderRadius** (`app_spacing.dart`)
Unified border radius scale.

**Radius Scale:**
- `xs` = 4px (subtle)
- `sm` = 8px (tight)
- `md` = 12px (standard)
- `lg` = 16px (rounded)
- `xl` = 20px (significant)
- `xxl` = 24px (very rounded)
- `full` = 999px (pill/circle)

**Pre-configured BorderRadius:**
- `radiusXs`, `radiusSm`, `radiusMd`, `radiusLg`, `radiusXl`, `radiusXxl`, `radiusFull`
- `radiusTopXxl`, `radiusBottomXxl`
- `radiusTopLeftLg`, `radiusTopRightLg`, `radiusBottomLeftLg`, `radiusBottomRightLg`

## 📝 Usage Examples

### Before (Hardcoded):
```dart
// ❌ Inconsistent, repeated hardcoding
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Color(0xFFB23A3A),
    borderRadius: BorderRadius.circular(12),
  ),
  child: Text(
    'Submit',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Color(0xFFFFFFFF),
    ),
  ),
)
```

### After (Design Tokens):
```dart
// ✅ Consistent, reusable, maintainable
import 'package:classcare_user/theme/app_design_tokens.dart';

Container(
  padding: AppSpacing.paddingButton,
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: AppBorderRadius.radiusMd,
  ),
  child: Text(
    'Submit',
    style: AppTypography.buttonMedium.copyWith(
      color: AppColors.surfaceLight,
    ),
  ),
)
```

## 🌓 Dark Mode Support

All colors have light/dark variants:

```dart
// Light mode
backgroundColor: AppColors.bgLight,
textColor: AppColors.textPrimaryLight,

// Dark mode
backgroundColor: AppColors.bgDark,
textColor: AppColors.textPrimaryDark,

// OR use helper methods
backgroundColor: AppColors.bgByTheme(brightness),
textColor: AppColors.textPrimaryByTheme(brightness),
```

## 🎨 Migration Checklist

### Phase 1: Colors
- [ ] Replace `Color(0xFFB23A3A)` with `AppColors.primary`
- [ ] Replace `Color(0xFFF8F8F8)` with `AppColors.bgLight`
- [ ] Replace `Color(0xFFFFFFFF)` with `AppColors.surfaceLight`
- [ ] Replace all custom hardcoded colors with AppColors equivalents
- [ ] Add dark mode support with `ByTheme()` methods

### Phase 2: Typography
- [ ] Replace `FontWeight.w700` with `AppTypography.weightBold`
- [ ] Replace custom `TextStyle` with predefined ones (e.g., `AppTypography.heading1`)
- [ ] Standardize all font sizes to scale

### Phase 3: Spacing
- [ ] Replace `padding: EdgeInsets.all(16)` with `padding: AppSpacing.paddingLg`
- [ ] Replace `margin: EdgeInsets.all(20)` with `margin: AppSpacing.marginXl`
- [ ] Replace hardcoded `SizedBox(height: 16)` with `SizedBox(height: AppSpacing.lg)`

### Phase 4: Border Radius
- [ ] Replace `BorderRadius.circular(12)` with `AppBorderRadius.radiusMd`
- [ ] Replace `BorderRadius.circular(24)` with `AppBorderRadius.radiusXxl`
- [ ] Replace inconsistent radius values with standardized scale

## 📚 File Locations
- Colors: `lib/theme/app_colors.dart`
- Typography: `lib/theme/app_typography.dart`
- Spacing/Radius: `lib/theme/app_spacing.dart`
- Motion: `lib/theme/motion_tokens.dart`
- **All Exports:** `lib/theme/app_design_tokens.dart`

## 🔧 Quick Import
```dart
import 'package:classcare_user/theme/app_design_tokens.dart';

// Now available:
// - AppColors.*
// - AppTypography.*
// - AppSpacing.*
// - AppBorderRadius.*
// - MotionTokens.*
```

## 💡 Tips & Best Practices

1. **Use constants for theme-specific colors:**
   ```dart
   final bgColor = AppColors.bgByTheme(Theme.of(context).brightness);
   ```

2. **Combine text styles with color:**
   ```dart
   Text(
     'Hello',
     style: AppTypography.heading1.copyWith(
       color: AppColors.textPrimaryLight,
     ),
   )
   ```

3. **Use spacing for consistency:**
   ```dart
   Column(
     mainAxisSize: MainAxisSize.min,
     spacing: AppSpacing.lg,
     children: [...],
   )
   ```

4. **Combine border radius with shapes:**
   ```dart
   OutlinedButton(
     style: OutlinedButton.styleFrom(
       shape: RoundedRectangleBorder(
         borderRadius: AppBorderRadius.radiusMd,
       ),
     ),
     onPressed: () {},
     child: Text('Button'),
   )
   ```

5. **Create custom variants when needed:**
   ```dart
   TextStyle customHeading = AppTypography.heading3.copyWith(
     color: AppColors.primary,
     letterSpacing: 1.0,
   );
   ```

## 🚀 Next Steps

1. ✅ Design tokens are created
2. ⏳ Refactor existing screens to use tokens (home_page, report_page, main.dart)
3. ⏳ Test dark mode support
4. ⏳ Update MaterialApp theme with dark variant
5. ⏳ Document any project-specific additions

---

**Last Updated:** April 25, 2026
**Version:** 1.0
