import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';

class CounterButton extends StatelessWidget {
  final VoidCallback onTap;
  final Icon icon;
  final String tooltip;
  const CounterButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: CustomColor.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
        ),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: icon,
          style: IconButton.styleFrom(
            fixedSize: Size(40.w, 40.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
            ),
          ),
        ),
      ),
    );
  }
}
