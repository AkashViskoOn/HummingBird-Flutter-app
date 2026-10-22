import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_spacing.dart';

class InputContainer extends StatelessWidget {
  const InputContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      width: 0.92.sw,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
        color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kWhite,
        border: Border.all(
          color: isDark
              ? CustomColor.kDarkBorder
              : CustomColor.kLightBorder.withValues(alpha: 0.6),
        ),
        boxShadow: isDark ? AppShadow.none : AppShadow.cardLight,
      ),
      child: child,
    );
  }
}
