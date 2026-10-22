import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ScheduleIntervals extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isSelected;
  const ScheduleIntervals(
      {super.key,
      required this.onTap,
      required this.label,
      required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(right: 10.r),
        child: Chip(
          labelPadding: EdgeInsets.symmetric(horizontal: 5.w),
          backgroundColor: isSelected
              ? CustomColor.kPrimaryColor
              : isDark
                  ? CustomColor.kDarkSurface2
                  : CustomColor.kTextOnDark,
          side: BorderSide(
            color: isSelected
                ? CustomColor.kPrimaryColor
                : isDark
                    ? CustomColor.kDarkBorder
                    : CustomColor.kLightBorder,
          ),
          label: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
                color: isSelected
                    ? CustomColor.kTextOnDark
                    : isDark
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary),
          ),
          visualDensity: VisualDensity.compact,
          avatar: Icon(
            Icons.schedule,
            size: 20.r,
            color: isSelected
                ? CustomColor.kTextOnDark
                : CustomColor.kPrimaryColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
          ),
          elevation: isSelected ? 3 : 0,
          shadowColor: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
