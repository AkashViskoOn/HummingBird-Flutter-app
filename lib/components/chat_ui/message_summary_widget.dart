import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';

class MessageSummaryWidget extends StatelessWidget {
  const MessageSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Obx(() {
      final summary = chatController.conversationSummary.value;
      if (summary.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.all(AppSpacing.xl.r),
        margin: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.w, vertical: AppSpacing.xs.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CustomColor.kPrimaryLight.withValues(alpha: 0.5),
              CustomColor.kUltraLightPrimary,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          border: Border.all(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.md.r),
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg.r),
              ),
              child: Icon(
                Icons.summarize_rounded,
                color: CustomColor.kPrimaryColor,
                size: AppIcons.lg.r,
              ),
            ),
            SizedBox(width: AppSpacing.lg.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversation Summary',
                    style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CustomColor.kPrimaryColor,
                      letterSpacing: null,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs.h),
                  Text(
                    summary,
                    style: AppTextStyles.bodySm,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
