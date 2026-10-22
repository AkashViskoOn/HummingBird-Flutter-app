import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class OtherMessage extends StatelessWidget {
  final String message;
  final String messageId;
  const OtherMessage({super.key, required this.message, this.messageId = ''});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final msgId =
        messageId.isNotEmpty ? messageId : message.hashCode.toString();
    final category = chatController.getMessageCategory(msgId);
    final sentiment = chatController.getMessageSentiment(msgId);
    final isSpam = chatController.isMessageSpam(msgId);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundImage: Image.asset("assets/images/user4.jpg").image,
              ),
              if (sentiment.isNotEmpty)
                Positioned(
                  bottom: -2.h,
                  right: -2.r,
                  child: Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: BoxDecoration(
                      color: CustomColor.kTextOnDark,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _sentimentEmoji(sentiment),
                      style: TextStyle(fontSize: 10.sp),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 0.70.sw),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty && category != 'general')
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h, left: 4.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color:
                              _categoryColor(category).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.xs.r),
                        ),
                        child: Text(
                          category[0].toUpperCase() + category.substring(1),
                          style: AppTextStyles.chatTime.copyWith(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _categoryColor(category),
                          ),
                        ),
                      ),
                    ),
                  if (isSpam)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h, left: 4.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: CustomColor.kDangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.xs.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 12.r, color: CustomColor.kDangerRed),
                            SizedBox(width: 4.w),
                            Text(
                              'Spam',
                              style: AppTextStyles.chatTime.copyWith(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: CustomColor.kDangerRed),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 3.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(18.r),
                        bottomRight: Radius.circular(18.r),
                        bottomLeft: Radius.circular(18.r),
                        topLeft: Radius.circular(4.r),
                      ),
                      color: CustomColor.kReceivedBubble,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message,
                      style: AppTextStyles.bodyMd,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sentimentEmoji(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
      case 'happy':
        return '😊';
      case 'negative':
      case 'sad':
      case 'angry':
        return '😞';
      case 'exciting':
      case 'excited':
        return '🎉';
      case 'love':
        return '❤️';
      default:
        return '😐';
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'greeting':
        return CustomColor.kSuccess;
      case 'question':
        return CustomColor.kInfo;
      case 'urgent':
        return CustomColor.kDangerRed;
      case 'appreciation':
        return CustomColor.kGoldAccent;
      case 'meeting':
        return CustomColor.kPrimaryMedium;
      case 'personal':
        return CustomColor.kPrimaryColor;
      case 'promotional':
        return CustomColor.kGoldAccent;
      default:
        return CustomColor.kTextTertiary;
    }
  }
}
