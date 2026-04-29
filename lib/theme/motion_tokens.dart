import 'package:flutter/material.dart';

/// Production-Ready Motion Design Tokens
/// 
/// This file defines all animation durations, curves, and distances
/// used throughout the ClassCare app to ensure consistency and performance.
/// 
/// See MOTION_SYSTEM.md for complete motion system documentation.

class MotionTokens {
  MotionTokens._(); // Private constructor

  // ─── DURATIONS ───────────────────────────────────────────────────────────

  /// Fast interactions: button press, quick feedback, micro-interactions
  /// Use: 150ms for press/release feedback
  static const Duration fast = Duration(milliseconds: 150);

  /// Fast-Medium: quick state changes, input focus, loading indicators
  /// Use: 200ms for focus states, error messages, validation feedback
  static const Duration fastMedium = Duration(milliseconds: 200);

  /// Medium: screen transitions, major state changes, button interactions
  /// Use: 300ms for page transitions, dialog opens, nav switches
  static const Duration medium = Duration(milliseconds: 300);

  /// Standard: page entry, card reveals, multi-element sequences
  /// Use: 400ms for single-page animations, card lifts
  static const Duration standard = Duration(milliseconds: 400);

  /// Slow: complex sequences, staggered reveals, background effects
  /// Use: 600ms for multi-card reveals with stagger
  static const Duration slow = Duration(milliseconds: 600);

  /// Very Slow: hero animations, celebration moments, complex sequences
  /// Use: 720ms for checkmark success, full-page entry sequences
  static const Duration verySlow = Duration(milliseconds: 720);

  // ─── EASING CURVES ───────────────────────────────────────────────────────

  /// Entrance curve (accelerating deceleration)
  /// Use: For elements appearing/entering the screen
  /// Feels smooth, natural deceleration
  static const Curve entranceCurve = Curves.easeOutCubic;

  /// Exit curve (accelerating acceleration)
  /// Use: For elements leaving/exiting the screen
  /// Feels like elements are speeding away
  static const Curve exitCurve = Curves.easeInCubic;

  /// Standard curve (neutral motion)
  /// Use: For cyclical animations, pulsing, generic transitions
  /// Balanced feel, not entering or exiting
  static const Curve standardCurve = Curves.easeInOutCubic;

  /// Elastic curve (springy, with overshoot)
  /// ⚠️ Use sparingly: Only for celebratory moments (success checkmark)
  /// Feels playful, must be justified
  static const Curve elasticCurve = Curves.elasticOut;

  /// Linear curve (constant speed)
  /// ⚠️ Use sparingly: Only for continuous progress (loading bars, timers)
  /// Feels mechanical if overused
  static const Curve linearCurve = Curves.linear;

  // ─── ANIMATION DISTANCES ──────────────────────────────────────────────────

  /// Standard slide distance for page transitions
  /// Use: Page entry/exit slide animations (20px horizontal or vertical)
  static const double slideDistance = 20.0;

  /// Lift distance for cards and elements
  /// Use: Card entry animations, hover effects (8px upward)
  static const double liftDistance = 8.0;

  /// Press scale factor for button feedback
  /// Use: When user taps a button (scale down to 0.98)
  static const double scalePress = 0.98;

  /// Hover scale factor for interactive elements
  /// Use: When hovering over buttons on desktop (scale up to 1.02)
  static const double scaleHover = 1.02;

  /// Overshoot scale for celebration animations
  /// Use: Success checkmark (scales to 1.2, then settles to 1.0)
  static const double scaleOvershoot = 1.2;

  // ─── STAGGER INTERVALS ────────────────────────────────────────────────────

  /// Stagger offset between cascading elements
  /// Use: Card reveals, text entry sequences
  /// Typically: Item N starts at offset N × 100ms
  static const Duration staggerOffset = Duration(milliseconds: 100);

  /// Duration window for each staggered element
  /// Use: When combined with offset, creates overlap
  /// Example: Element 1: 0% → 25%, Element 2: 20% → 45%, etc.
  static const Duration staggerWindow = Duration(milliseconds: 280);

  // ─── OPACITY RANGES ───────────────────────────────────────────────────────

  /// Opacity for disabled states (not animating, static)
  static const double disabledOpacity = 0.55;

  /// Opacity for hover states on desktop
  static const double hoverOpacity = 0.85;

  /// Opacity for loading/pulsing background (minimum)
  static const double pulseOpacityMin = 0.6;

  /// Opacity for loading/pulsing background (maximum)
  static const double pulseOpacityMax = 1.0;

  // ─── HELPER: GET ADAPTIVE DURATION ─────────────────────────────────────

  /// Returns adjusted duration based on device animation settings
  /// 
  /// Respects user's "disable animations" system setting
  /// Call within build() context like:
  /// ```dart
  /// final duration = MotionTokens.getAdaptiveDuration(context, MotionTokens.medium);
  /// ```
  static Duration getAdaptiveDuration(BuildContext context, Duration baseDuration) {
    if (MediaQuery.of(context).disableAnimations) {
      return Duration.zero;
    }
    return baseDuration;
  }

  // ─── HELPER: BUILD STAGGER INTERVAL ──────────────────────────────────────

  /// Creates a staggered interval curve for cascading animations
  /// 
  /// Example: For 5 items over 720ms timeline:
  /// ```dart
  /// for (int i = 0; i < 5; i++) {
  ///   final curve = MotionTokens.buildStaggerInterval(i, 5, 0.72);
  ///   // Use curve in CurvedAnimation
  /// }
  /// ```
  static Interval buildStaggerInterval(
    int itemIndex,
    int totalItems,
    double totalProgress, // 0.0 to 1.0 (e.g., 0.72 for 720ms out of 1000ms)
  ) {
    final itemDuration = totalProgress / totalItems;
    final overlap = totalProgress - (itemDuration * 0.8);
    final begin = itemIndex * (itemDuration - overlap);
    final end = begin + itemDuration;

    return Interval(
      begin.clamp(0.0, 1.0),
      end.clamp(0.0, 1.0),
      curve: entranceCurve,
    );
  }
}

// ─── COMMON ANIMATION COMBINATIONS ──────────────────────────────────────────

/// Pre-built animation curves for reuse
/// 
/// These combine duration + easing for common patterns
class AnimationCombos {
  AnimationCombos._();

  /// Fade in + slide up (card entry)
  static const fadeSlideUp = (
    duration: MotionTokens.standard,
    curve: MotionTokens.entranceCurve,
    distance: MotionTokens.liftDistance,
  );

  /// Fade in + slide right (page entry from left)
  static const fadeSlideRight = (
    duration: MotionTokens.medium,
    curve: MotionTokens.entranceCurve,
    distance: MotionTokens.slideDistance,
  );

  /// Fade out + slide down (page exit)
  static const fadeSlideDown = (
    duration: MotionTokens.medium,
    curve: MotionTokens.exitCurve,
    distance: MotionTokens.slideDistance,
  );

  /// Scale + rotate (celebration)
  static const scaleRotate = (
    duration: MotionTokens.verySlow,
    curve: MotionTokens.elasticCurve,
    scale: MotionTokens.scaleOvershoot,
  );

  /// Button press feedback
  static const buttonPress = (
    duration: MotionTokens.fast,
    curve: MotionTokens.entranceCurve,
    scale: MotionTokens.scalePress,
  );

  /// Input focus transition
  static const inputFocus = (
    duration: MotionTokens.fastMedium,
    curve: MotionTokens.entranceCurve,
  );
}
