import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_colors.dart';

class MediaSourceBottomSheet extends StatelessWidget {
  final String mediaName;
  const MediaSourceBottomSheet({super.key, required this.mediaName});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (context) {
        return Container(
          height: context.height * 0.25,
          padding: EdgeInsets.only(
              left: AppSpacing.section.w,
              right: AppSpacing.section.w,
              top: AppSpacing.section.h,
              bottom: AppSpacing.lg.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pick File',
                    style: AppTextStyles.headingLg
                        .copyWith(color: AppColors.kPrimary),
                  ),
                ],
              ),
              SizedBox(
                height: AppSpacing.xxxl.h,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: SizedBox(
                  width: double.maxFinite,
                  child: Text(
                    'Phone',
                    style: AppTextStyles.headingLg
                        .copyWith(color: AppColors.kPrimary),
                  ),
                ),
              ),
              SizedBox(
                height: AppSpacing.xs.h,
              ),
              Divider(color: CustomColor.kLightBorder),
              SizedBox(
                height: AppSpacing.xl.h,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: SizedBox(
                  width: double.maxFinite,
                  child: Text(
                    'Camera',
                    style: AppTextStyles.headingLg
                        .copyWith(color: AppColors.kPrimary),
                  ),
                ),
              ),
              SizedBox(
                height: 5.h,
              ),
              Divider(color: CustomColor.kLightBorder),
            ],
          ),
        );
      },
    );
  }
}
