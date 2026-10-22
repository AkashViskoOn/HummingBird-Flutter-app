import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/profile_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerBottomSheet extends StatelessWidget {
  final void Function(ImageSource)? onPickImage;
  final VoidCallback? onRemoveImage;
  final bool Function()? hasImage;

  const ImagePickerBottomSheet({
    super.key,
    this.onPickImage,
    this.onRemoveImage,
    this.hasImage,
  });

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.find();
    final bool showRemove = hasImage?.call() ??
        (onPickImage == null && onRemoveImage == null
            ? profileController.hasProfileImage
            : false);
    return SafeArea(
      bottom: true,
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl.r, vertical: AppSpacing.xl.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pick Image',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingLg,
            ),
            SizedBox(height: AppSpacing.lg.h),
            _ProfilePickOption(
              icon: Icons.photo_library_rounded,
              label: 'Photos',
              onTap: () {
                Get.back();
                if (onPickImage != null) {
                  onPickImage!(ImageSource.gallery);
                } else {
                  profileController.pickProfilePic(ImageSource.gallery);
                }
              },
            ),
            SizedBox(height: AppSpacing.xs.h),
            _ProfilePickOption(
              icon: Icons.photo_camera_rounded,
              label: 'Camera',
              onTap: () {
                Get.back();
                if (onPickImage != null) {
                  onPickImage!(ImageSource.camera);
                } else {
                  profileController.pickProfilePic(ImageSource.camera);
                }
              },
            ),
            if (showRemove && onRemoveImage != null) ...[
              SizedBox(height: AppSpacing.xs.h),
              _ProfilePickOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Image',
                isDanger: true,
                onTap: () {
                  Get.back();
                  onRemoveImage!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfilePickOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _ProfilePickOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent =
        isDanger ? CustomColor.kDangerRed : CustomColor.kPrimaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.rounded.r),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg.w, vertical: AppSpacing.md.h),
        decoration: BoxDecoration(
          color: CustomColor.kUltraLightBg,
          borderRadius: BorderRadius.circular(AppRadius.rounded.r),
          border: Border.all(
            color: accent.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: AppIcons.huge.r,
              height: AppIcons.huge.r,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accent, size: AppIcons.xl.r),
            ),
            SizedBox(width: AppSpacing.md.w),
            Text(
              label,
              style: AppTextStyles.headingSm.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
