# ClassCare Motion System
**Production-Ready Motion Design Guide**

---

## 1. Motion Principles

### 1.1 Core Philosophy
Every animation in ClassCare must serve a purpose. Motion is **not decoration**—it communicates, guides, and reinforces trust.

### 1.2 Five Core Principles

| Principle | Definition | Example |
|-----------|-----------|---------|
| **Purposeful** | Every motion has intent (clarify state, guide attention, confirm action) | Report submission success → animated checkmark reinforces completion |
| **Fast & Responsive** | Feels immediate (not sluggish), but not rushed | Button press: 200ms feedback, 300ms transition |
| **Subtle & Trustworthy** | Understated, professional, non-distracting | Gentle fade (300-400ms) vs bouncy/playful animations |
| **Spatial Clarity** | Motion reveals hierarchy, depth, and relationships | Page slide reveals new content, cards float upward = importance |
| **Accessible & Inclusive** | Respects user preferences (prefers-reduced-motion) | Offer instant fallback: fade without slide, no parallax |

---

## 2. Animation Tokens (Global System)

### 2.1 Duration Scales
```dart
// Fast: User feedback, micro-interactions
const kFastDuration = Duration(milliseconds: 200);

// Medium: Screen transitions, major state changes
const kMediumDuration = Duration(milliseconds: 300);

// Standard: Page entry/exit, card reveals
const kStandardDuration = Duration(milliseconds: 400);

// Slow: Background effects, multi-step sequences
const kSlowDuration = Duration(milliseconds: 600);

// Very Slow: Hero animations, complex sequences
const kVerySlowDuration = Duration(milliseconds: 720);
```

### 2.2 Easing Curves
```dart
// Entrance (accelerating deceleration)
const kEntranceCurve = Curves.easeOutCubic;

// Exit (accelerating acceleration)
const kExitCurve = Curves.easeInCubic;

// Standard (neutral, natural)
const kStandardCurve = Curves.easeInOutCubic;

// Elastic (playful, only for special cases like error shake)
const kElasticCurve = Curves.elasticOut;

// Linear (only for continuous progress, loading bars)
const kLinearCurve = Curves.linear;
```

### 2.3 Stagger Interval System
For sequenced animations (page entry, card reveals):
```dart
// Interval(begin, end, curve)
// Each element gets 100ms window with 50ms offset

// Element 1: 0% → 25% of timeline
// Element 2: 20% → 45% of timeline
// Element 3: 40% → 65% of timeline
// etc.

// Result: Smooth, cascading reveal effect (720ms total)
```

---

## 3. Transition System (Between Screens)

### 3.1 Navigation Rules

| Navigation Path | Transition Type | Direction | Duration | Easing |
|---|---|---|---|---|
| **Primary Nav (Home ↔ Report)** | Fade + Slide | Horizontal (enter: right, exit: left) | 300ms | easeOutCubic |
| **Primary Nav (Report → Success)** | Fade + Slide | Upward (vertical slide) | 300ms | easeOutCubic |
| **Secondary Nav (Track → TrackResult)** | Fade + Slide | Horizontal (right-to-left) | 300ms | easeOutCubic |
| **Back Navigation** | Fade + Slide | Reverse direction | 300ms | easeInCubic |
| **Replace (Success → Home)** | Fade Only | None (no slide) | 300ms | easeOutCubic |
| **Bottom Nav Tabs** | Fade Only | None (instant, no spatial movement) | 200ms | easeOut |

### 3.2 Transition Implementation Pattern

**Standard Fade + Slide Transition:**
```dart
PageRouteBuilder<void> _buildFadeSlideRoute(
  Widget page, {
  bool slideFromRight = true,
}) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(
        begin: Offset(slideFromRight ? 1 : -1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
```

**Vertical Slide Transition (for modals/dialogs):**
```dart
PageRouteBuilder<void> _buildVerticalSlideRoute(Widget page) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return SlideTransition(position: slide, child: child);
    },
  );
}
```

**Bottom Navigation Tabs (Fade Only):**
```dart
// No slide, instant switch (tabs stay in place)
// Fade duration: 200ms
// This avoids spatial confusion on tab switching
```

---

## 4. Screen-by-Screen Motion Behavior

### 4.1 Home Page (Landing)

**Entry Animation:**
```
Timeline (720ms total):
├─ Header: 0% → 25% (fade + slight slide up)
├─ Hero CTA: 20% → 40% (fade + slide up)
├─ Feature Cards (3x): 40% → 60%, 50% → 70%, 60% → 80% (staggered fade + lift)
└─ System Activity: 70% → 100% (fade + slide up)
```

**Card Lift Effect:**
- On entry: Cards slide up 20px + fade in
- On interaction: Subtle elevation increase (shadow darkens)
- Scale: None (avoid distortion)

**System Activity Refresh:**
- Button tap: 200ms scale down (0.95) + color shift
- Loading: Pulsing opacity (0.6 → 1.0, 1000ms loop)
- Completion: Brief success color flash (100ms)

### 4.2 Report Page (User Input)

**Entry Animation:**
```
Timeline (400ms total):
├─ Header: 0% → 30% (fade)
├─ Anonymous Badge: 20% → 50% (fade + slight lift)
└─ Category Grid Container: 40% → 100% (fade)
```

**Category Card Interaction:**
- **Unselected state:** 
  - Opacity: 1.0, Scale: 1.0
  - Border: light gray, Box shadow: subtle
  
- **Tap feedback:**
  - Duration: 150ms (fast)
  - Scale: 0.98 (subtle press)
  - Opacity: 0.8
  - Curve: easeOut
  
- **Selected state (animated):**
  - Duration: 280ms
  - Border color → primary red (animated)
  - Background → light red tint
  - Checkmark badge: slides in from top-right (100ms delay)
  - Curve: easeOutCubic

**Input Field Focus:**
- Border color transition: 200ms
- Shadow expansion: 200ms
- Icon color: matches border (synchronized)
- Text appearance: immediate (no delay)

**Description Character Counter:**
- Color state (immediate):
  - 0 chars: neutral gray
  - 1-19 chars: warning orange
  - 20+ chars (valid): success green
  - 500+ chars (over limit): error red
- Text fade between states: 100ms

**Submit Button Loading State:**
- **Disabled appearance:**
  - Opacity: 0.55
  - Color: gray (no red)
  - Scale: 1.0 (no pointer events)
  
- **Enabled appearance:**
  - Opacity: 1.0
  - Color: full red
  - Elevation: 4.0
  - Interactive: true
  
- **Loading animation:**
  - Dot pulse: 3x dots, 1000ms loop, opacity 0.3 → 1.0
  - Text animates in: "Submitting" + dots
  - Duration: 220ms switch

**Error/Success Messages:**
- Slide up from bottom + fade in (280ms)
- Auto-dismiss after 2200ms
- Smooth slide down + fade out on dismiss

### 4.3 Track Page (Search/Lookup)

**Entry Animation:**
```
Timeline (400ms total):
├─ Header: 0% → 30% (fade)
├─ Input Field: 20% → 50% (fade + slight lift)
└─ Help Text: 40% → 100% (fade)
```

**Search Input Interaction:**
- Focus: border + shadow expand (200ms)
- Search icon: color animates to primary (200ms)
- Cursor: standard Flutter behavior (no custom animation)

**Search Result Loading:**
- Pulsing container background (subtle): 1000ms loop
- Text fade in gradually as data loads

### 4.4 Success Page (Confirmation)

**Entry Animation:**
```
Timeline (800ms total):
├─ Checkmark Icon: Animate scale + rotate (0 → 1, 0° → 360°) at 20% → 80%
├─ Title: 30% → 60% (fade + slide up)
├─ Tracking ID: 40% → 70% (fade + lift, emphasized)
├─ Stats Cards: 50% → 100% (staggered fade + lift)
└─ CTAs: 70% → 100% (staggered fade)
```

**Checkmark Animation (Hero Moment):**
```dart
// Celebrates success, captures attention
Duration: 600ms
Sequence:
  1. Scale from 0 → 1.2 (overshoot) + rotate 0° → 360°
  2. Settle to 1.0 with slight bounce
  3. Opacity: 0 → 1 concurrently
  Curve: Curves.elasticOut (only exception to easeOut rule - justified for celebration)
```

**Tracking ID Card:**
- Emphasis: larger shadow, slight scale up (1.0 → 1.02) on entry
- Copy button: shows tooltip "Copied!" with 200ms fade in/out
- Text selection disabled (prevent accidental selection)

**Stats Cards Cascade:**
- Each card: 100ms stagger
- Motion: fade + 10px upward slide
- Curve: easeOutCubic

**CTA Button Animation:**
- Tap: immediate 150ms scale (0.98)
- Ripple: standard Material ripple (enabled)

### 4.5 Track Result Page (Status Display)

**Entry Animation:**
```
Timeline (600ms total):
├─ Header: 0% → 20% (fade)
├─ Status Badge: 15% → 40% (fade + scale pulse)
├─ Status Timeline: 30% → 80% (items cascade)
└─ Description/AI Summary: 60% → 100% (fade + slide up)
```

**Status Badge Pulse:**
- Only when status is "In Review" or "Pending"
- Pulse: opacity 0.8 → 1.0, 1500ms loop, easeInOutCubic
- Color indicates status (green = resolved, yellow = review, blue = submitted)

**Timeline Status Items:**
- Each item: fade + slide in from left (40px)
- Stagger: 80ms between each
- Connector lines: animate drawing (path animation)

**Real-Time Updates (from Supabase stream):**
- Status change: 300ms color transition (fade between colors)
- New badge appears: 200ms scale in (0 → 1)
- AI summary refresh: fade to gray (100ms), refresh data, fade back (100ms)

---

## 5. Microinteraction Patterns

### 5.1 Button Press Feedback

**Pressable Scale Component** (existing):
```dart
// On press:
// - Scale: 1.0 → 0.98 (150ms)
// - Curve: easeOut
// On release:
// - Scale: 0.98 → 1.0 (150ms)
// - Curve: easeOut

// This provides tactile feedback without being distracting
```

### 5.2 Text Stagger Entry

**Reusable Stagger Animation Function:**
```dart
Widget _buildStaggeredText(
  String text,
  TextStyle style, {
  required Animation<double> animation,
  double beginInterval = 0.0,
  double endInterval = 1.0,
}) {
  final animationCurved = CurvedAnimation(
    parent: animation,
    curve: Interval(beginInterval, endInterval, curve: Curves.easeOutCubic),
  );
  
  return FadeTransition(
    opacity: animationCurved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(animationCurved),
      child: Text(text, style: style),
    ),
  );
}
```

### 5.3 Card Lift Effect

**Reusable Card Animation:**
```dart
Widget _buildAnimatedCard(
  Widget child, {
  required Animation<double> animation,
  double beginInterval = 0.0,
  double endInterval = 1.0,
}) {
  final animationCurved = CurvedAnimation(
    parent: animation,
    curve: Interval(beginInterval, endInterval, curve: Curves.easeOutCubic),
  );
  
  return FadeTransition(
    opacity: animationCurved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(animationCurved),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animationCurved),
        child: child,
      ),
    ),
  );
}
```

### 5.4 Loading Indicator Pattern

**Pulsing Dots (used in form submission):**
```dart
// Animated opacity loop with staggered timing
// Each dot peaks at different times
// Creates sense of progress without actual progress bar
// 1000ms cycle time
```

### 5.5 Validation State Animation

**Input Field Error State:**
```dart
// Border color: normal → error (200ms)
// Background: white → light red tint (100ms)
// Icon: fade to error icon (150ms)
// Error message: slides up + fades in (250ms)
// Curve: all animations use easeOut (no bounce)
```

---

## 6. Feedback & System States

### 6.1 Success States

| State | Motion | Duration | Message |
|-------|--------|----------|---------|
| **Report Submitted** | Checkmark scale + rotate (0→1 + 360°) | 600ms | "Your report has been submitted" |
| **Item Copied** | Brief color flash + scale | 200ms | Tooltip: "Copied to clipboard!" |
| **Form Valid** | Border glow (green tint) | 200ms | Text counter turns green |

### 6.2 Error States

| State | Motion | Duration | Message |
|-------|--------|----------|---------|
| **Validation Failed** | Shake (3x horizontal oscillation) | 400ms | Border turns red, icon red |
| **Server Error** | Fade + scale in error banner | 300ms | "Something went wrong..." |
| **Network Timeout** | Pulsing container (background) | 1500ms loop | "Waiting for server..." |

### 6.3 Loading States

| State | Motion | Duration | Pattern |
|-------|--------|----------|---------|
| **Form Submission** | Pulsing dots + text morph | 1000ms loop | "Submitting •••" |
| **Search/Lookup** | Pulsing background container | 1000ms loop | Subtle opacity 0.8 → 1.0 |
| **Realtime Updates** | Subtle badge pulse | 1500ms loop | Only for "pending" status |

### 6.4 Disabled States

**Visual Treatment (No Animation):**
- Opacity: 0.55 (no fade-to-disabled animation)
- Color: grayed out (immediate, no transition)
- Cursor: not-allowed
- No interaction events (pointer events disabled)

**Rationale:** Disabled states should feel "off"—no animation reinforces that the action is unavailable.

---

## 7. Hierarchy & Attention Control

### 7.1 Attention Hierarchy

**Tier 1: Highest Priority**
- Page entry animations (sequence draws eye top-to-bottom)
- Checkmark success animation (celebrate achievement)
- Error shake animation (demands attention)
- Primary CTAs (button focus on entry)

**Tier 2: Medium Priority**
- Card reveals (feature highlights)
- Input field focus states
- Status badge updates (realtime)

**Tier 3: Low Priority (Subtle)**
- Micro-interactions (button press, hover)
- Pulsing loaders (background)
- Tooltip fades

### 7.2 Motion-Guided User Flow

**Home Page:**
- Hero banner + CTA attracts attention first
- Features cascade below (discovery)
- System Activity at bottom (supplementary)

**Report Page:**
- Category selection dominates (large, animated)
- Input fields are secondary (standard focus)
- Submit button highlights at bottom

**Success Page:**
- Checkmark animation captures attention (celebration)
- Tracking ID emphasized (critical info)
- Actions cascade below (next steps)

**Track Page:**
- Search input focused immediately
- Results fade in as they load

---

## 8. Performance Optimization

### 8.1 Performance Targets
- **Target FPS:** 60 FPS on Snapdragon 6-series & equivalent (mid-range devices)
- **Animation Frame Budget:** < 16.67ms per frame
- **Memory Impact:** < 2MB additional for animation controllers

### 8.2 Best Practices

**DO:**
```dart
// ✅ Use AnimationController with TickerProviderStateMixin
late final AnimationController _controller;

// ✅ Use CurvedAnimation for controlled easing
final _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

// ✅ Dispose all controllers
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

// ✅ Use Interval for staggered animations
CurvedAnimation(parent: _controller, curve: Interval(0.0, 0.25));

// ✅ Use AnimatedContainer for simple property changes
AnimatedContainer(duration: kMediumDuration, color: targetColor);

// ✅ Use TweenAnimationBuilder for one-off animations
TweenAnimationBuilder<double>(
  duration: kMediumDuration,
  tween: Tween(begin: 0, end: 1),
  builder: (context, value, child) => Opacity(opacity: value, child: child),
);
```

**DON'T:**
```dart
// ❌ Multiple overlapping AnimationControllers (use one parent controller)
// ❌ setState() inside animation callback (use ValueListenableBuilder)
// ❌ Complex transforms on large widget trees (avoid nested scaling)
// ❌ Animations in initState without disposal strategy
// ❌ addListener() on animation without cleanup
// ❌ AnimatedBuilder for non-animation state changes
```

### 8.3 Device-Level Optimization

**Low-End Devices (< 2GB RAM):**
- Skip staggered animations, use simple fade only
- Reduce shadow effects
- Use `kFastDuration` instead of `kStandardDuration`

**Mid-Range Devices (2-4GB RAM):**
- Full motion system (default)
- All stagger animations enabled
- Standard shadows and effects

**High-End Devices (> 4GB RAM):**
- Enable all effects as designed
- No performance compromises

**Implementation:**
```dart
bool get _isLowEndDevice {
  // Detect device capabilities and adjust motion accordingly
  return deviceMemoryMB < 2000;
}

Duration get _scaledDuration {
  return _isLowEndDevice 
    ? kFastDuration 
    : kMediumDuration;
}
```

### 8.4 GPU Acceleration

**High-Performance Operations:**
- Scale transform (GPU-accelerated)
- Opacity changes (GPU-accelerated)
- Slide/Translate (GPU-accelerated)

**Lower-Performance Operations:**
- Width/height changes (triggers layout)
- Color changes on large widgets (CPU-intensive)
- Shadow changes (recomputes shader)

**Optimization:**
```dart
// ✅ Good: Uses GPU acceleration
Transform.scale(scale: 1.02, child: Card(...))

// ❌ Avoid: Triggers layout recalculation
SizedBox(width: animatedWidth, child: Card(...))
```

---

## 9. Consistency System

### 9.1 Global Animation Constants

**Create a new file: `lib/theme/motion_tokens.dart`**

```dart
class MotionTokens {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration fastMedium = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration standard = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 720);

  // Curves
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve elasticCurve = Curves.elasticOut;

  // Distances
  static const double slideDistance = 20.0;
  static const double liftDistance = 8.0;
  static const double scalePress = 0.98;
}
```

### 9.2 Reusable Animation Widgets

**Create: `lib/user/widgets/motion_widgets.dart`**

```dart
// Reusable components for consistent motion across screens
class FadeSlideIn extends StatelessWidget { ... }
class CardLiftIn extends StatelessWidget { ... }
class StaggeredPageEntry extends StatelessWidget { ... }
class LoadingPulse extends StatelessWidget { ... }
class SuccessCheckmark extends StatelessWidget { ... }
```

### 9.3 Motion Rules Checklist

**Before shipping any animation, verify:**
- [ ] Duration matches token system (not arbitrary milliseconds)
- [ ] Curve is one of 5 defined curves (not custom)
- [ ] Animation has clear purpose (not purely decorative)
- [ ] Tested on Snapdragon 6-series (60 FPS sustained)
- [ ] Accessibility: respects prefers-reduced-motion
- [ ] Disposed properly (no memory leaks)
- [ ] Performance profiler shows < 16.67ms frame time

---

## 10. Accessibility

### 10.1 Reduced Motion Support

**Respect User Preferences:**
```dart
bool get prefersReducedMotion {
  return MediaQuery.of(context).disableAnimations;
}

Duration get _adaptiveDuration {
  return prefersReducedMotion 
    ? Duration.zero 
    : MotionTokens.medium;
}
```

**Fallback Behavior:**
- Fade animations: instant (no fade duration)
- Slide animations: skip (fade only)
- Stagger sequences: collapse to simultaneous fade
- Loading animations: show text-only ("Loading...")

### 10.2 Color-Blind Safe Animation

**Don't rely solely on color shifts:**
- Success: checkmark ✓ + green + text confirmation
- Error: shake animation + red border + icon + text
- Loading: pulsing + text indicator (not just color change)

---

## 11. Do's & Don'ts

### DO ✅

| Rule | Reason |
|------|--------|
| Use 300ms for primary transitions | Feels responsive, not rushed |
| Stagger card entry by 100ms intervals | Natural cascade, easier to follow |
| Apply scale 0.98 on button press | Subtle feedback, device-like |
| Fade success messages over 280ms | Draws attention without shock |
| Use easeOutCubic for entrance animations | Feels smooth, not linear |
| Dispose all AnimationControllers | Prevent memory leaks |
| Test on mid-range device (Snapdragon 6) | Ensure 60 FPS target |
| Combine opacity + position for focus | Creates clear hierarchy |

### DON'T ❌

| Anti-Pattern | Why It's Bad |
|---|---|
| Animations over 800ms (unless hero moment) | Feels slow, users assume frozen |
| Bounce/elastic for error states | Feels playful, undermines severity |
| Pure decorative animation (confetti, particles) | Distracts from task, wastes GPU |
| Simultaneous animations on all text | Chaotic, hard to focus |
| Color-only state feedback (no motion) | Not accessible, easily missed |
| AnimationControllers in build() | Recreates on every frame, crashes app |
| Linear easing for UI transitions | Feels mechanical, unnatural |
| Large scale transforms (> 1.2x) | Distorts UI, looks glitchy |
| Custom curves without reason | Adds complexity, may perform poorly |

---

## 12. Implementation Roadmap

### Phase 1: Core Tokens (Foundation)
- [ ] Create `motion_tokens.dart` with all durations/curves
- [ ] Add `prefers-reduced-motion` detection
- [ ] Document in team wiki

### Phase 2: Reusable Components (Building Blocks)
- [ ] `FadeSlideIn` widget (universal screen transition)
- [ ] `CardLiftIn` widget (card reveals)
- [ ] `StaggeredPageEntry` (page sequences)
- [ ] `SuccessCheckmark` (celebration animation)
- [ ] `LoadingPulse` (all loaders)

### Phase 3: Screen Implementation (Per-Screen)
- [ ] **Home Page:** Staggered entry, card lift, system activity pulse
- [ ] **Report Page:** Category selection feedback, input focus, submission loader
- [ ] **Track Page:** Input focus, search results fade-in
- [ ] **Success Page:** Checkmark hero, tracking ID emphasis, CTA cascade
- [ ] **Track Result Page:** Status badge pulse, timeline cascade, realtime updates

### Phase 4: Polish & Testing (QA)
- [ ] Validate 60 FPS on Snapdragon 6-series
- [ ] Test reduced-motion mode
- [ ] Cross-browser testing (Chrome, Safari)
- [ ] Device testing (phone, tablet, landscape)

### Phase 5: Documentation (Team Handoff)
- [ ] Motion design specs in Figma/Miro
- [ ] Code comments with animation rationale
- [ ] Performance guidelines in team wiki
- [ ] Troubleshooting guide for devs

---

## 13. Advanced Techniques (Optional)

### 13.1 Hero Animation (Tracking ID Focus)

**Only if valuable:**
```dart
// Shared element animation: Tracking ID on Success Page
// Flies to top-left corner (like iOS app switcher)
// Creates visual connection between states

// Implementation: Wrap in Hero widget
Hero(
  tag: 'trackingId',
  child: Text(trackingId),
)
```

**Trade-off:** +40ms interpolation, complex to debug. **Skip unless critical UX win.**

### 13.2 Gesture-Driven Transitions

**Back swipe (iOS-like):**
- Swipe right: page slides out, previous page slides in
- Requires custom gesture detector
- Risk: can conflict with native Android back gesture

**Decision:** Skip for now (bottom nav handles navigation). Revisit if user requests.

### 13.3 Shared Axis Transitions (Material Design)

**Advanced pattern:** Page transitions share a common spatial axis
- Opening modal: Z-axis (card rises from background)
- Opening settings: X-axis (slides horizontally)
- Opening subpage: Y-axis (slides vertically)

**Trade-off:** Complex to implement, minimal UX benefit for ClassCare. **Skip.**

---

## 14. Summary: Motion System at a Glance

```
┌─ Motion System Overview ──────────────────────────────────┐
│                                                            │
│  PRINCIPLES: Purposeful, fast, subtle, spatial, trustworthy
│                                                            │
│  TOKENS:                                                   │
│  • Durations: 150ms, 200ms, 300ms, 400ms, 600ms, 720ms   │
│  • Curves: easeOutCubic (entrance), easeInCubic (exit)    │
│  • Stagger: 100ms intervals for cascades                  │
│                                                            │
│  TRANSITIONS:                                              │
│  • Primary nav: Fade + horizontal slide (300ms)           │
│  • Modal/dialog: Fade + vertical slide (300ms)            │
│  • Replace nav: Fade only (300ms)                         │
│  • Tab switching: Fade only (200ms)                       │
│                                                            │
│  SCREEN MOTION:                                            │
│  • Home: Staggered header + cards + activity (720ms)      │
│  • Report: Fade header + category card selection + form   │
│  • Success: Hero checkmark + tracking ID emphasis         │
│  • Track Result: Status badge pulse + timeline cascade    │
│                                                            │
│  MICROINTERACTIONS:                                        │
│  • Button press: Scale 0.98 (150ms)                       │
│  • Input focus: Border color + shadow (200ms)             │
│  • Form error: Shake + red border (400ms)                 │
│  • Success toast: Slide up + fade (280ms)                 │
│                                                            │
│  PERFORMANCE:                                              │
│  • Target: 60 FPS on Snapdragon 6+                        │
│  • GPU-accelerate scale, translate, opacity               │
│  • Dispose all controllers, respect reduced-motion        │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## 15. Reference: Flutter Animation APIs

**Official Documentation:**
- [Animation & Motion - Flutter Docs](https://flutter.dev/docs/development/ui/animations)
- [Material Motion - Material Design](https://material.io/design/motion/)
- [Curves - Flutter Docs](https://api.flutter.dev/flutter/animation/Curves-class.html)

**Recommended Packages:**
- `animations` (Material transitions)
- `visibility_detector` (detect when widgets appear/disappear)
- `performance_testing` (profile 60 FPS compliance)

---

## 16. Questions to Revisit

1. **Should we add haptic feedback on button presses?** (Flutter: `HapticFeedback.lightImpact()`)
   - Pro: Tactile feedback on mobile
   - Con: Not supported on all devices, adds complexity
   - **Decision:** Add after Phase 3 if time permits

2. **Do we need dark mode motion adjustments?**
   - Reduced shadow contrast in dark mode
   - Same motion timing (not affected by theme)
   - **Decision:** Handle in Phase 4 QA

3. **Should animations respect system animation speed settings?**
   - Some Android devices have animation speed multiplier (0.5x, 1x, 2x, 10x)
   - Manual adjustment not recommended (Flutter already respects this)
   - **Decision:** Flutter handles automatically, no action needed

---

## Appendix: Animation Timing Calculator

**Quick reference for planning animations:**

| Timeline | Events |
|----------|--------|
| 0ms | Page enter begins |
| 0-120ms | Header fades in |
| 80-200ms | Hero CTA slides in |
| 200-320ms | Feature card 1 |
| 280-400ms | Feature card 2 |
| 360-480ms | Feature card 3 |
| 440-600ms | System Activity |
| 600ms+ | All animations complete |

**Stagger math:** If you have N items, total timeline = 600ms base + (N-1) × 100ms offset

