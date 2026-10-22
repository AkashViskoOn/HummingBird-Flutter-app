import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class GroupImagePickerBottomSheet extends StatelessWidget {
  final String roomId;

  const GroupImagePickerBottomSheet({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.find();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: CustomColor.kTextOnDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: CustomColor.kTextTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.xxs.r),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Change Group Photo',
            style:
                AppTextStyles.titleSm.copyWith(color: CustomColor.kTextPrimary),
          ),
          SizedBox(height: 4.h),
          Text(
            'Choose an option to update the group image',
            style: AppTextStyles.subtitle
                .copyWith(color: CustomColor.kTextSecondary),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _PickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Get.back();
                    groupController.pickGroupImage(ImageSource.gallery, roomId);
                  },
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _PickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    groupController.pickGroupImage(ImageSource.camera, roomId);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomColor.kUltraLightBg,
      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            children: [
              Container(
                height: 52.r,
                width: 52.r,
                decoration: const BoxDecoration(
                  color: CustomColor.kPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24.r,
                  color: CustomColor.kPrimaryColor,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                label,
                style: AppTextStyles.titleSm
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
