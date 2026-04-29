import 'dart:math';

import 'package:flutter/material.dart';
import 'package:classcare_user/theme/motion_tokens.dart';

/// Reusable animation widgets for consistent motion across ClassCare
/// 
/// All widgets respect prefers-reduced-motion accessibility setting
/// See MOTION_SYSTEM.md for motion system documentation

// ─────────────────────────────────────────────────────────────────────────────
// 1. FADE & SLIDE ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Standard fade + slide animation for screen transitions
/// 
/// Usage:
/// ```dart
/// FadeSlideIn(
///   direction: AxisDirection.right,
///   child: MyPage(),
/// )
/// ```
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final AxisDirection direction;
  final Duration? duration;
  final Duration? delay;

  const FadeSlideIn({
    Key? key,
    required this.child,
    this.direction = AxisDirection.right,
    this.duration,
    this.delay,
  }) : super(key: key);

  Offset _getBeginOffset() {
    return switch (direction) {
      AxisDirection.right => const Offset(-1, 0),
      AxisDirection.left => const Offset(1, 0),
      AxisDirection.down => const Offset(0, -1),
      AxisDirection.up => const Offset(0, 1),
    };
  }

  @override
  Widget build(BuildContext context) {
    final prefersReducedMotion = MediaQuery.of(context).disableAnimations;
    final finalDuration = duration ?? MotionTokens.medium;

    if (prefersReducedMotion) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: finalDuration,
      curve: MotionTokens.entranceCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: _getBeginOffset() *
                MotionTokens.slideDistance *
                (1 - value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CARD ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Card fade + lift animation
/// 
/// Usage:
/// ```dart
/// CardLiftIn(
///   beginInterval: 0.3,
///   endInterval: 0.6,
///   child: Card(...),
/// )
/// ```
class CardLiftIn extends StatelessWidget {
  final Widget child;
  final double beginInterval;
  final double endInterval;
  final Animation<double>? parentAnimation;

  const CardLiftIn({
    Key? key,
    required this.child,
    this.beginInterval = 0.0,
    this.endInterval = 1.0,
    this.parentAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prefersReducedMotion = MediaQuery.of(context).disableAnimations;

    if (prefersReducedMotion || parentAnimation == null) {
      return child;
    }

    final staggeredAnimation = CurvedAnimation(
      parent: parentAnimation!,
      curve: Interval(
        beginInterval,
        endInterval,
        curve: MotionTokens.entranceCurve,
      ),
    );

    return FadeTransition(
      opacity: staggeredAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, MotionTokens.liftDistance / 100),
          end: Offset.zero,
        ).animate(staggeredAnimation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(staggeredAnimation),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. PAGE ENTRY ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Full page staggered entry animation
/// 
/// Automatically animates children with staggered intervals
/// 
/// Usage:
/// ```dart
/// StaggeredPageEntry(
///   duration: MotionTokens.verySlow,
///   children: [
///     Header(),
///     CTA(),
///     FeatureCard1(),
///     FeatureCard2(),
///   ],
/// )
/// ```
class StaggeredPageEntry extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final double staggerFraction; // Portion of timeline for stagger (0.0-1.0)

  const StaggeredPageEntry({
    Key? key,
    required this.children,
    this.duration = MotionTokens.verySlow,
    this.staggerFraction = 0.8, // Elements stagger across 80% of timeline
  }) : super(key: key);

  @override
  State<StaggeredPageEntry> createState() => _StaggeredPageEntryState();
}

class _StaggeredPageEntryState extends State<StaggeredPageEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefersReducedMotion = MediaQuery.of(context).disableAnimations;

    if (prefersReducedMotion) {
      return Column(children: widget.children);
    }

    return Column(
      children: List.generate(
        widget.children.length,
        (index) {
          final totalItems = widget.children.length;
          final itemWindow = widget.staggerFraction / totalItems;
          final overlap =
              widget.staggerFraction - (itemWindow * 0.8);
          final begin = index * (itemWindow - overlap);
          final end = (begin + itemWindow).clamp(0.0, 1.0);

          final staggeredAnimation = CurvedAnimation(
            parent: _controller,
            curve: Interval(
              begin.clamp(0.0, 1.0),
              end,
              curve: MotionTokens.entranceCurve,
            ),
          );

          return FadeTransition(
            opacity: staggeredAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(staggeredAnimation),
              child: widget.children[index],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. LOADING ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Loading pulse animation
/// 
/// Usage:
/// ```dart
/// LoadingPulse(
///   child: Container(), // Will pulse opacity
/// )
/// ```
class LoadingPulse extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const LoadingPulse({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<LoadingPulse> createState() => _LoadingPulseState();
}

class _LoadingPulseState extends State<LoadingPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: MotionTokens.pulseOpacityMin,
        end: MotionTokens.pulseOpacityMax,
      ).animate(
        CurvedAnimation(parent: _controller, curve: MotionTokens.standardCurve),
      ),
      child: widget.child,
    );
  }
}

/// Animated pulsing dots (for loading indicators)
/// 
/// Usage:
/// ```dart
/// PulsingDots(
///   label: "Submitting",
/// )
/// ```
class PulsingDots extends StatefulWidget {
  final String label;
  final Duration duration;

  const PulsingDots({
    Key? key,
    this.label = "Loading",
    this.duration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label),
        const SizedBox(width: 8),
        ...List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final phase = (_controller.value + index * 0.2) % 1;
              final opacity =
                  0.3 + (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.7;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Opacity(
                  opacity: opacity,
                  child: const Icon(Icons.circle, size: 6),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. SUCCESS & CELEBRATION ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Success checkmark animation (celebration moment)
/// 
/// Usage:
/// ```dart
/// SuccessCheckmark(
///   size: 80,
///   color: Colors.green,
/// )
/// ```
class SuccessCheckmark extends StatefulWidget {
  final double size;
  final Color color;

  const SuccessCheckmark({
    Key? key,
    this.size = 80,
    this.color = Colors.green,
  }) : super(key: key);

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.verySlow,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefersReducedMotion = MediaQuery.of(context).disableAnimations;

    if (prefersReducedMotion) {
      return Icon(
        Icons.check_circle_outline,
        size: widget.size,
        color: widget.color,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Scale with overshoot (0 → 1.2 → 1.0)
        final scaleValue = t < 0.6
            ? Curves.elasticOut.transform(t / 0.6) * MotionTokens.scaleOvershoot
            : 1.0 + (MotionTokens.scaleOvershoot - 1.0) * (1 - t);

        // Opacity fade in
        final opacity = (t * 2).clamp(0.0, 1.0);

        // Rotation 0° → 360°
        final rotation = t * 2 * 3.14159265359;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scaleValue,
            child: Transform.rotate(
              angle: rotation,
              child: Icon(
                Icons.check_circle,
                size: widget.size,
                color: widget.color,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. ERROR & STATE ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Shake animation (for errors, validation failures)
/// 
/// Usage:
/// ```dart
/// ShakeAnimation(
///   child: TextField(...),
/// )
/// ```
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShakeAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = sin(_controller.value * 3 * 3.14159265359) * 10;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. INTERACTIVE ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

/// Pressable widget with scale feedback
/// 
/// Existing component, kept for reference
/// Located in report_page.dart as _PressableScale
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const PressableScale({
    Key? key,
    required this.child,
    this.onTap,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionTokens.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: MotionTokens.scalePress)
        .animate(CurvedAnimation(parent: _controller, curve: MotionTokens.entranceCurve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.enabled) {
      widget.onTap?.call();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
