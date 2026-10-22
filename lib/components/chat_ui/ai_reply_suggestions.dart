import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AiReplySuggestions extends StatelessWidget {
  final bool autoSend;
  const AiReplySuggestions({super.key, this.autoSend = false});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Obx(() {
      if (chatController.aiReplySuggestions.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: chatController.aiReplySuggestions.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final suggestion = chatController.aiReplySuggestions[index];
                    return _SuggestionChip(
                      label: suggestion,
                      onTap: () {
                        if (autoSend) {
                          chatController.textMessageController.text =
                              suggestion;
                          chatController.toggleSendButton.value = true;
                          chatController.sendMessage();
                        } else {
                          chatController.textMessageController.text =
                              suggestion;
                          chatController.textMessageController.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: chatController
                                    .textMessageController.text.length),
                          );
                          chatController.toggleSendButton.value = true;
                        }
                        chatController.clearReplySuggestions();
                      },
                      onDismiss: () {
                        final remaining = List<String>.from(
                            chatController.aiReplySuggestions);
                        remaining.removeAt(index);
                        chatController.aiReplySuggestions.value = remaining;
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: () => chatController.clearReplySuggestions(),
              child: Container(
                width: 24.r,
                height: 24.r,
                decoration: BoxDecoration(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    size: 14.r, color: CustomColor.kTextTertiary),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: CustomColor.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm
                    .copyWith(color: CustomColor.kTextOnDark),
              ),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded,
                  size: 14.r,
                  color: CustomColor.kTextOnDark.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
