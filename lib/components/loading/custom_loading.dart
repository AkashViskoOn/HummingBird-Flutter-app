import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class CustomLoading extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;

  const CustomLoading({super.key, this.message, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size ?? AppIcons.xxxl.r,
            height: size ?? AppIcons.xxxl.r,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? CustomColor.kPrimaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: 12.h),
            Text(
              message!,
              style: AppTextStyles.bodyMd.copyWith(
                color: CustomColor.kTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget shimmer({double width = double.infinity, double height = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: CustomColor.kLightBorder,
        borderRadius: BorderRadius.circular(AppRadius.md.r),
      ),
    );
  }

  static Widget cardShimmer() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: CustomColor.kLightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              shimmer(width: 40.r, height: 40.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    shimmer(width: 120.w),
                    SizedBox(height: 6.h),
                    shimmer(width: 80.w),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          shimmer(width: double.infinity),
          SizedBox(height: 6.h),
          shimmer(width: 200.w),
        ],
      ),
    );
  }
}
