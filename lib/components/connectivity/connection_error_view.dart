import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Premium "Couldn't connect" state shown when a screen fails to load because
/// the device is offline. [onRetry] must call the EXISTING fetch/retry method
/// of the owning screen — this widget never performs its own network call.
class ConnectionErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const ConnectionErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Entrance(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76.r,
                height: 76.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CustomColor.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.30),
                      blurRadius: 20.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  color: CustomColor.kTextOnDark,
                  size: 30.r,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                "Couldn't connect",
                textAlign: TextAlign.center,
                style:
                    (dark ? AppTextStyles.titleMdOnDark : AppTextStyles.titleMd)
                        .copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6.h),
              Text(
                'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style:
                    (dark ? AppTextStyles.bodySmOnDark : AppTextStyles.bodySm)
                        .copyWith(fontSize: 12.sp),
              ),
              SizedBox(height: 18.h),
              PressScale(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onRetry,
                    borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    child: AnimatedContainer(
                      duration: AppAnimation.normal,
                      padding: EdgeInsets.symmetric(
                        horizontal: 26.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: CustomColor.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                        boxShadow: [
                          BoxShadow(
                            color: CustomColor.kPrimaryColor
                                .withValues(alpha: 0.30),
                            blurRadius: 12.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: CustomColor.kTextOnDark, size: 18.r),
                          SizedBox(width: 8.w),
                          Text(
                            'Retry',
                            style: AppTextStyles.button.copyWith(
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
