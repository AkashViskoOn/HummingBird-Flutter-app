import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_shadow.dart';

class EmojieBottomSheet extends StatelessWidget {
  const EmojieBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (_) {
        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.w, vertical: AppSpacing.xxxl.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Humming Stickers', style: AppTextStyles.headingLg),
              SizedBox(
                height: AppSpacing.lg.h,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Container(
                      width: AppIcons.huge.r,
                      height: AppIcons.huge.r,
                      padding: EdgeInsets.all(AppSpacing.xs.r),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.r),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CustomColor.kUltraLightBg,
                          boxShadow: AppShadow.cardLight),
                      child: Text(
                        '🕒',
                      ),
                    ),
                    Container(
                      width: AppIcons.huge.r,
                      height: AppIcons.huge.r,
                      padding: EdgeInsets.all(AppSpacing.xxs.r),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.r),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CustomColor.kUltraLightBg),
                      child: Text(
                        '😀',
                        style: TextStyle(fontSize: AppSpacing.xxxl.sp),
                      ),
                    ),
                    Container(
                      width: AppIcons.huge.r,
                      height: AppIcons.huge.r,
                      padding: EdgeInsets.all(AppSpacing.xs.r),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.r),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.grey),
                      child: Text(
                        '🧙‍♀',
                        style: TextStyle(fontSize: AppSpacing.xxxl.sp),
                      ),
                    ),
                    Container(
                      width: AppIcons.huge.r,
                      height: AppIcons.huge.r,
                      padding: EdgeInsets.all(AppSpacing.xs.r),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.r),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.grey),
                      child: Text(
                        '🌹',
                        style: TextStyle(fontSize: AppSpacing.xxxl.sp),
                      ),
                    ),
                    Container(
                      width: AppIcons.huge.r,
                      height: AppIcons.huge.r,
                      padding: EdgeInsets.all(AppSpacing.xs.r),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.r),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.grey),
                      child: Text(
                        '🏢',
                        style: TextStyle(fontSize: AppSpacing.xxxl.sp),
                      ),
                    ),
                    Container(
                      width: AppIcons.huge.r,
                      height: AppIcons.huge.r,
                      padding: EdgeInsets.all(AppSpacing.xs.r),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.r),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.grey),
                      child: Text(
                        '🎈',
                        style: TextStyle(fontSize: AppSpacing.xxxl.sp),
                      ),
                    ),
                    Container(
                      width: AppIcons.huge.r,
                      height: AppIcons.huge.r,
                      padding: EdgeInsets.all(AppSpacing.xs.r),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.r),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.grey),
                      child: Text(
                        '🍕',
                        style: TextStyle(fontSize: AppSpacing.xxxl.sp),
                      ),
                    ),
                    Container(
                      width: AppIcons.huge.r,
                      height: AppIcons.huge.r,
                      padding: EdgeInsets.all(AppSpacing.xs.r),
                      margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs.r),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.grey),
                      child: Text(
                        '🚗',
                        style: TextStyle(fontSize: AppSpacing.xxxl.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: Get.height * 0.15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('0 Stickers found',
                      style: AppTextStyles.headingMd
                          .copyWith(color: CustomColor.kTextTertiary)),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
