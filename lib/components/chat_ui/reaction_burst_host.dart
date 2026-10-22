import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';

/// Instagram-style reaction animations layered on top of a chat bubble.
///
/// Two moves, both driven by controller counters (no GlobalKeys, safe inside
/// recycled list views):
/// - `reactionBursts[messageId]` (double-tap) → big heart pops at the bubble
///   center with an elastic scale and fades out.
/// - `reactionPulses[messageId]` (socket `message-reaction-update`) → a small
///   emoji floats up from the reaction-chip corner, connectivity-driven.
class ReactionBurstHost extends StatefulWidget {
  final String messageId;
  final String? reactionsJson;
  final Widget child;

  const ReactionBurstHost({
    super.key,
    required this.messageId,
    this.reactionsJson,
    required this.child,
  });

  @override
  State<ReactionBurstHost> createState() => _ReactionBurstHostState();
}

class _ReactionBurstHostState extends State<ReactionBurstHost> {
  RxInt? _pulse;
  RxInt? _burst;
  int _lastPulse = 0;
  int _lastBurst = 0;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    final ctrl = Get.find<ChatController>();
    _pulse = ctrl.reactionPulses[widget.messageId];
    _lastPulse = _pulse?.value ?? 0;
    _burst = ctrl.reactionBursts[widget.messageId];
    _lastBurst = _burst?.value ?? 0;
    _pulse?.listen((v) {
      if (mounted && v != _lastPulse) setState(() => _lastPulse = v);
    });
    _burst?.listen((v) {
      if (mounted && v != _lastBurst) setState(() => _lastBurst = v);
    });
  }

  @override
  void dispose() {
    _pulse?.close();
    _burst?.close();
    super.dispose();
  }

  String _reactionEmoji() {
    final raw = widget.reactionsJson;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded.isNotEmpty) {
          return decoded.keys.first.toString();
        }
      } catch (_) {}
    }
    return '❤️';
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _reactionEmoji();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        // Big center pop on double-tap (Instagram-style heart burst).
        if (_lastBurst > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('burst_$_lastBurst'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOut,
                builder: (context, t, _) {
                  final pop =
                      Curves.elasticOut.transform((t / 0.4).clamp(0.0, 1.0));
                  final scale =
                      t < 0.4 ? pop * 1.35 : (1.05 - 0.35 * ((t - 0.4) / 0.6));
                  final opacity = t < 0.45 ? 1.0 : (1.0 - (t - 0.45) / 0.55);
                  return Center(
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale.clamp(0.0, 1.0),
                        child: Text(emoji, style: TextStyle(fontSize: 46.r)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        // Small floating emoji rising from the reaction chip on socket pulses.
        if (_lastPulse > 0)
          Positioned(
            right: 8.w,
            bottom: -2.h,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('float_$_lastPulse'),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) {
                  final fadeIn = (t / 0.15).clamp(0.0, 1.0);
                  final fadeOut = ((1 - (t - 0.15) / 0.85)).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: fadeIn * fadeOut,
                    child: Transform.translate(
                      offset: Offset(0, -36.h * t),
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * t,
                        child: Text(emoji, style: TextStyle(fontSize: 22.r)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
