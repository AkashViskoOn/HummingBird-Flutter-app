import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class SentimentIndicator extends StatelessWidget {
  final String messageId;
  const SentimentIndicator({super.key, required this.messageId});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Obx(() {
      final sentiment = chatController.getMessageSentiment(messageId);
      if (sentiment.isEmpty) return const SizedBox.shrink();

      return GestureDetector(
        onTap: () => _showSentimentDetails(context, sentiment),
        child: Container(
          padding: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            color: CustomColor.kTextOnDark,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CustomColor.kScrim20,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _sentimentEmoji(sentiment),
            style: TextStyle(fontSize: 12.sp),
          ),
        ),
      );
    });
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

  void _showSentimentDetails(BuildContext context, String sentiment) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                _sentimentEmoji(sentiment),
                style: TextStyle(fontSize: 48.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                _sentimentLabel(sentiment),
                style: AppTextStyles.headingMd
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
              SizedBox(height: 8.h),
              Text(
                _sentimentDescription(sentiment),
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle
                    .copyWith(color: CustomColor.kTextSecondary),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  String _sentimentLabel(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return 'Positive';
      case 'negative':
        return 'Negative';
      case 'happy':
        return 'Happy';
      case 'sad':
        return 'Sad';
      case 'angry':
        return 'Angry';
      case 'exciting':
      case 'excited':
        return 'Excited';
      case 'love':
        return 'Loving';
      default:
        return 'Neutral';
    }
  }

  String _sentimentDescription(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return 'This message has a positive tone.';
      case 'negative':
        return 'This message has a negative tone.';
      case 'happy':
        return 'The sender seems happy.';
      case 'sad':
        return 'The sender seems sad.';
      case 'angry':
        return 'The sender seems frustrated.';
      case 'exciting':
      case 'excited':
        return 'The sender seems excited.';
      case 'love':
        return 'The message conveys affection.';
      default:
        return 'This message has a neutral tone.';
    }
  }
}
