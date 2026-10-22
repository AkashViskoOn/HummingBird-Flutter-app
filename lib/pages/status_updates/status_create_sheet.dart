import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/pages/status_updates/status_media_editor_screen.dart';
import 'package:humming_bird/pages/status_updates/status_text_editor_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:image_picker/image_picker.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class StatusCreateSheet extends StatelessWidget {
  const StatusCreateSheet({super.key});

  Future<void> _pickFromCamera(BuildContext context, bool video) async {
    final picker = ImagePicker();
    try {
      final XFile? shot = video
          ? await picker.pickVideo(source: ImageSource.camera)
          : await picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 90,
            );
      if (shot != null) {
        Get.back();
        if (video) {
          Get.to(() => StatusMediaEditorScreen(
                mediaFile: File(shot.path),
                mediaType: 'video',
              ));
        } else {
          Get.to(() => StatusMediaEditorScreen(
                mediaFile: File(shot.path),
                mediaType: 'image',
              ));
        }
      }
    } catch (_) {
      CustomSnackbar.show(
          title: 'Camera unavailable', message: 'Could not open the camera');
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final images = await picker.pickMultiImage(imageQuality: 90, limit: 10);
      if (images.isNotEmpty) {
        Get.back();
        Get.to(() => StatusMediaEditorScreen(
              mediaFile: File(images.first.path),
              mediaType: 'image',
              queueFiles: images.map((e) => File(e.path)).toList(),
            ));
      }
    } catch (_) {
      CustomSnackbar.show(
          title: 'Gallery unavailable', message: 'Could not open the gallery');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? CustomColor.kDarkDivider
                      : CustomColor.kLightBorder,
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Create Status',
              style: AppTextStyles.headingMd.copyWith(
                  color: isDark
                      ? CustomColor.kTextOnDark
                      : CustomColor.kTextPrimary),
            ),
            SizedBox(height: 16.h),
            _CreateOption(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              subtitle: 'Capture a photo or video',
              color: CustomColor.kPrimaryColor,
              onTap: () => _showCameraChoice(context),
            ),
            _CreateOption(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              subtitle: 'Choose photos from your gallery',
              color: CustomColor.kOnlineGreen,
              onTap: () => _pickFromGallery(context),
            ),
            _CreateOption(
              icon: Icons.text_fields_rounded,
              label: 'Text Status',
              subtitle: 'Share text with colors, fonts & more',
              color: CustomColor.kGoldAccent,
              onTap: () {
                Get.back();
                Get.to(() => const StatusTextEditorScreen());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraChoice(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? CustomColor.kDarkSurface
              : CustomColor.kTextOnDark,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? CustomColor.kDarkDivider
                        : CustomColor.kLightBorder,
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _CreateOption(
                icon: Icons.photo_camera_rounded,
                label: 'Photo',
                subtitle: 'Take a photo for your status',
                color: CustomColor.kPrimaryColor,
                onTap: () {
                  Get.back();
                  _pickFromCamera(context, false);
                },
              ),
              _CreateOption(
                icon: Icons.videocam_rounded,
                label: 'Video',
                subtitle: 'Record a short video',
                color: CustomColor.kOnlineGreen,
                onTap: () {
                  Get.back();
                  _pickFromCamera(context, true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CreateOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
        child: Icon(icon, color: color, size: 22.r),
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyMd.copyWith(
            color: isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(color: CustomColor.kTextTertiary),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14.r,
        color:
            isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary,
      ),
      onTap: onTap,
    );
  }
}
