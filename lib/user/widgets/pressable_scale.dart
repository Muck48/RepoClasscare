import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:classcare_user/theme/app_design_tokens.dart';

enum HapticType { selection, light, medium }

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.splashColor,
    this.highlightColor,
    this.hapticType = HapticType.selection,
    this.semanticLabel,
    this.semanticHint,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final BorderRadius borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  final HapticType hapticType;
  final String? semanticLabel;
  final String? semanticHint;
  final String? tooltip;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    if (!widget.enabled) return;
    setState(() => _scale = pressed ? 0.97 : 1);
  }

  void _fireHaptic() {
    switch (widget.hapticType) {
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          AnimatedScale(
            scale: _scale,
            duration: MotionTokens.fast,
            curve: MotionTokens.entranceCurve,
            child: widget.child,
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: widget.borderRadius,
                splashColor: widget.splashColor ??
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                highlightColor: widget.highlightColor ??
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                onTap: widget.enabled ? widget.onTap : null,
                onHighlightChanged: (pressed) {
                  _setPressed(pressed);
                  if (pressed) {
                    _fireHaptic();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }

    if (widget.semanticLabel != null) {
      content = Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.semanticLabel!,
        hint: widget.semanticHint,
        child: content,
      );
    }

    return content;
  }
}
