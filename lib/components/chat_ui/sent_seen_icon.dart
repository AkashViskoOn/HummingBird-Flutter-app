import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/theme/app_icons.dart';

class SentSeenIcon extends StatelessWidget {
  final bool isSeen;
  const SentSeenIcon({super.key, required this.isSeen});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.check,
          color: isSeen ? Colors.lightBlue : Colors.grey,
          size: AppIcons.xs.r,
        ),
        Positioned(
          bottom: 1.h,
          left: -4,
          child: Icon(
            Icons.check,
            color: isSeen ? Colors.lightBlue : Colors.grey,
            size: AppIcons.xs.r,
          ),
        ),
      ],
    );
  }
}
