import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Notifications sheet shown from the home header bell.
///
/// Deliberately does NOT list scheduled messages as notifications — those live
/// under the Schedule tab. Kept as a clean empty state until a real
/// notification feed is wired in.
class ScheduleNotificationSheet extends StatelessWidget {
  const ScheduleNotificationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: isDark
                  ? CustomColor.kTextOnDarkMuted.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(AppRadius.xxs.r),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  gradient: CustomColor.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                ),
                child: Icon(Icons.notifications_active_rounded,
                    color: CustomColor.kTextOnDark, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Text(
                'Notifications',
                style: isDark
                    ? AppTextStyles.headingMdOnDark
                    : AppTextStyles.headingMd,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 40.r, color: CustomColor.kTextTertiary),
                SizedBox(height: 12.h),
                Text(
                  'No notifications yet',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDarkMuted
                        : CustomColor.kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'You will see notifications here when they arrive.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDarkMuted
                        : CustomColor.kTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
