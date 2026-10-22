import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';

class PinnedMessagesBar extends StatelessWidget {
  const PinnedMessagesBar({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Obx(() {
      if (!chatController.showPinnedBar.value ||
          chatController.pinnedMessages.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.w, vertical: AppSpacing.md.h),
        decoration: BoxDecoration(
          color: CustomColor.kUltraLightPrimary,
          border: Border(
            bottom: BorderSide(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.push_pin_rounded,
                size: AppIcons.sm.r, color: CustomColor.kPrimaryColor),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final firstPinned = chatController.pinnedMessages.first;
                  chatController.scrollToMessage(firstPinned.mId!);
                },
                child: Text(
                  '${chatController.pinnedMessages.length} pinned message${chatController.pinnedMessages.length > 1 ? 's' : ''}',
                  style: AppTextStyles.subtitle
                      .copyWith(color: CustomColor.kPrimaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            InkWell(
              onTap: () => chatController.showPinnedBar.value = false,
              borderRadius: BorderRadius.circular(AppRadius.md.r),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xs.r),
                child: Icon(Icons.close_rounded,
                    size: AppIcons.md.r, color: CustomColor.kTextTertiary),
              ),
            ),
          ],
        ),
      );
    });
  }
}
