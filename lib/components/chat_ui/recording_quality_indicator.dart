import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';

class RecordingQualityIndicator extends StatelessWidget {
  const RecordingQualityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Obx(() {
      final quality = chatController.recordingQuality.value;
      Color bgColor;
      String label;
      switch (quality) {
        case 'low':
          bgColor = CustomColor.kWarning;
          label = 'LOW';
          break;
        case 'high':
          bgColor = CustomColor.kSuccess;
          label = 'HQ';
          break;
        default:
          bgColor = CustomColor.kPrimaryColor;
          label = 'MED';
      }
      return GestureDetector(
        onTap: () {
          final current = chatController.recordingQuality.value;
          final next = current == 'low'
              ? 'medium'
              : current == 'medium'
                  ? 'high'
                  : 'low';
          chatController.setRecordingQuality(next);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md.w, vertical: AppSpacing.xs.h),
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.md.r),
            border: Border.all(color: bgColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: AppIcons.xs.r, color: bgColor),
              SizedBox(width: AppSpacing.xs.w),
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 9.sp,
                  color: bgColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
