import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Pulsing shimmer-style skeleton used while status data loads.
class StatusSkeleton extends StatefulWidget {
  const StatusSkeleton({super.key});

  @override
  State<StatusSkeleton> createState() => _StatusSkeletonState();
}

class _StatusSkeletonState extends State<StatusSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_controller),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(),
          SizedBox(height: 14.h),
          _row(),
          SizedBox(height: 14.h),
          _row(),
        ],
      ),
    );
  }

  Widget _row() {
    return Row(
      children: [
        Container(
          width: 54.r,
          height: 54.r,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CustomColor.kLightBorder,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: CustomColor.kLightBorder,
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 90.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: CustomColor.kUltraLightBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
