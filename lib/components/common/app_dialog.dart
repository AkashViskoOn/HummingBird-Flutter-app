import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

enum AppDialogType { confirmation, delete, warning, error, success, info }

class AppDialog {
  static Future<T?> show<T>({
    required String title,
    required String message,
    AppDialogType type = AppDialogType.info,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool isDismissible = true,
  }) {
    final icon = _resolveIcon(type);
    final iconColor = _resolveIconColor(type);

    return Get.dialog<T>(
      barrierDismissible: isDismissible,
      PopScope(
        canPop: isDismissible,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: AnimatedScale(
              scale: 1.0,
              duration: AppAnimation.normal,
              curve: AppAnimation.easeOut,
              child: Entrance(
                  duration: const Duration(milliseconds: 250),
                  slide: false,
                  scale: true,
                  fade: true,
                  child: Container(
                    width: 320.w,
                    margin: EdgeInsets.symmetric(horizontal: AppSpacing.page.w),
                    padding: EdgeInsets.all(AppSpacing.section.w),
                    decoration: BoxDecoration(
                      color: CustomColor.kLightSurface,
                      borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Container(
                            width: 56.r,
                            height: 56.r,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xxl.r),
                            ),
                            child: Icon(icon, color: iconColor, size: 28.r),
                          ),
                          SizedBox(height: AppSpacing.xxl.h),
                        ],
                        Text(title,
                            style: AppTextStyles.headingMd,
                            textAlign: TextAlign.center),
                        SizedBox(height: AppSpacing.xl.h),
                        Text(message,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: CustomColor.kTextSecondary),
                            textAlign: TextAlign.center),
                        SizedBox(height: AppSpacing.section.h),
                        Row(
                          children: [
                            if (cancelText != null) ...[
                              Expanded(
                                child: AppButton(
                                  text: cancelText,
                                  onTap: onCancel ?? () => Get.back(),
                                  variant: AppButtonVariant.outlined,
                                  height: 44.h,
                                ),
                              ),
                              SizedBox(width: AppSpacing.xl.w),
                            ],
                            Expanded(
                              child: AppButton(
                                text: confirmText ?? 'OK',
                                onTap: onConfirm ?? () => Get.back(),
                                variant: type == AppDialogType.delete
                                    ? AppButtonVariant.danger
                                    : AppButtonVariant.primary,
                                height: 44.h,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ),
          ),
        ),
      ),
    );
  }

  static IconData? _resolveIcon(AppDialogType type) {
    switch (type) {
      case AppDialogType.confirmation:
        return Icons.help_outline_rounded;
      case AppDialogType.delete:
        return Icons.delete_outline_rounded;
      case AppDialogType.warning:
        return Icons.warning_amber_rounded;
      case AppDialogType.error:
        return Icons.error_outline_rounded;
      case AppDialogType.success:
        return Icons.check_circle_outline_rounded;
      case AppDialogType.info:
        return Icons.info_outline_rounded;
    }
  }

  static Color _resolveIconColor(AppDialogType type) {
    switch (type) {
      case AppDialogType.confirmation:
        return CustomColor.kInfo;
      case AppDialogType.delete:
        return CustomColor.kDangerRed;
      case AppDialogType.warning:
        return CustomColor.kWarning;
      case AppDialogType.error:
        return CustomColor.kDangerRed;
      case AppDialogType.success:
        return CustomColor.kSuccess;
      case AppDialogType.info:
        return CustomColor.kPrimaryColor;
    }
  }
}
