import 'dart:async';
import 'package:flutter/material.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class CountdownTimer extends StatefulWidget {
  final int epochSeconds;
  final TextStyle? textStyle;
  final Color? color;

  const CountdownTimer({
    super.key,
    required this.epochSeconds,
    this.textStyle,
    this.color,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = _calc();
      if (next != _remaining) setState(() => _remaining = next);
      if (_remaining <= 0 && _timer != null) {
        _timer!.cancel();
      }
    });
  }

  int _calc() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (widget.epochSeconds - now).clamp(0, widget.epochSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= 0) {
      return Text(
        'Publishing now',
        style: widget.textStyle ??
            AppTextStyles.error
                .copyWith(color: widget.color ?? CustomColor.kOnlineGreen),
      );
    }

    final hours = _remaining ~/ 3600;
    final minutes = (_remaining % 3600) ~/ 60;
    final seconds = _remaining % 60;

    final label = hours > 0
        ? '${hours}h ${minutes}m ${seconds}s'
        : '${minutes}m ${seconds}s';

    return Text(
      'in $label',
      style: widget.textStyle ??
          AppTextStyles.error
              .copyWith(color: widget.color ?? CustomColor.kGoldAccent),
    );
  }
}
