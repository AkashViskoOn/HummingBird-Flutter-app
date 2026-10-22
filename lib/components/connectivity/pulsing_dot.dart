import 'package:flutter/material.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Small breathing status dot used by the connectivity surfaces. The pulse is
/// a gentle 600ms scale + glow rhythm and is disabled when the OS asks for
/// reduced motion.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool animate;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 8,
    this.animate = true,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppAnimation.extraSlow,
    reverseDuration: AppAnimation.extraSlow,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery must be read here (not in initState) — dependOnInherited
    // widgets are illegal during initState and crash with
    // "dependOnInheritedWidgetOfExactType called before initState completed".
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.animate && !reduceMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.65 + 0.35 * _controller.value;
        final glow = (1.3 + 0.9 * _controller.value);
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: widget.size * glow,
            height: widget.size * glow,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.18),
            ),
            child: Center(
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: AppRadius.lg,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
