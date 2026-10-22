import 'package:flutter/material.dart';
import 'package:humming_bird/theme/app_animation.dart';

/// One-shot entrance animation (fade + slide + optional scale) for list
/// tiles, cards and page content. Re-runs only when first built — safe to
/// place inside reactive (Obx) list builders.
///
/// `delayFactor` (0..1) staggers items: the widget holds at its start value
/// for that fraction of `duration`, then animates — no controllers needed.
///
/// Honours the OS "Remove animations" accessibility setting by rendering the
/// child immediately, fully opaque and untransformed.
class Entrance extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double delayFactor;
  final bool fade;
  final bool slide;
  final bool scale;
  final Offset slideOffset;

  const Entrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.delayFactor = 0,
    this.fade = true,
    this.slide = true,
    this.scale = false,
    this.slideOffset = const Offset(0, 18),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    final curve = delayFactor > 0
        ? Interval(delayFactor.clamp(0.0, 0.8), 1.0,
            curve: AppAnimation.easeOut)
        : AppAnimation.easeOut;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        final v = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: fade ? v : 1.0,
          child: Transform.translate(
            offset: slide ? slideOffset * (1 - v) : Offset.zero,
            child: scale
                ? Transform.scale(scale: 0.94 + 0.06 * v, child: child)
                : child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Lightweight press feedback: scales the child down while pressed.
/// Uses a raw Listener so it never steals taps from the child's own
/// GestureDetector / InkWell. Skipped when the OS "Remove animations"
/// accessibility setting is on.
class PressScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final Duration duration;

  const PressScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.duration = AppAnimation.buttonPress,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: AppAnimation.easeOut,
        child: widget.child,
      ),
    );
  }
}
