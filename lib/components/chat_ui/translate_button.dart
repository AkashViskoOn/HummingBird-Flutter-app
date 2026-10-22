import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class TranslateButton extends StatelessWidget {
  final String messageId;
  final String message;
  const TranslateButton(
      {super.key, required this.messageId, required this.message});

  static const _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'hi', 'name': 'Hindi'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'zh', 'name': 'Chinese'},
    {'code': 'ja', 'name': 'Japanese'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'pt', 'name': 'Portuguese'},
    {'code': 'ru', 'name': 'Russian'},
  ];

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return GestureDetector(
      onTap: () => _showLanguagePicker(context, chatController),
      child: Container(
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: CustomColor.kTextOnDark.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppRadius.xs.r),
          border: Border.all(
              color: CustomColor.kTextTertiary.withValues(alpha: 0.2)),
        ),
        child: Icon(Icons.translate_rounded,
            size: 12.r, color: CustomColor.kPrimaryColor),
      ),
    );
  }

  void _showLanguagePicker(
      BuildContext context, ChatController chatController) {
    final hasTranslation =
        chatController.messageTranslations[messageId] != null;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              Text(
                'Translate Message',
                style: AppTextStyles.headingMd
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
              SizedBox(height: 4.h),
              Text(
                'Select a language to translate',
                style: AppTextStyles.subtitle
                    .copyWith(color: CustomColor.kTextSecondary),
              ),
              SizedBox(height: 16.h),
              if (hasTranslation)
                Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: CustomColor.kUltraLightPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      border: Border.all(
                          color: CustomColor.kPrimaryColor
                              .withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.translate_rounded,
                                size: 16.r, color: CustomColor.kPrimaryColor),
                            SizedBox(width: 6.w),
                            Text(
                              'Translated',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: CustomColor.kPrimaryColor),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          chatController
                              .messageTranslations[messageId]!.values.first,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: CustomColor.kTextPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                height: 200.h,
                child: ListView.separated(
                  itemCount: _languages.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1.h, color: CustomColor.kLightBorder),
                  itemBuilder: (_, index) {
                    final lang = _languages[index];
                    return ListTile(
                      leading: Icon(
                        Icons.language_rounded,
                        color: CustomColor.kPrimaryColor,
                        size: 20.r,
                      ),
                      title: Text(
                        lang['name']!,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: CustomColor.kTextPrimary),
                      ),
                      trailing: chatController
                                  .messageTranslations[messageId]?.keys
                                  .contains(lang['code']) ==
                              true
                          ? Icon(Icons.check_rounded,
                              color: CustomColor.kSuccess, size: 20.r)
                          : null,
                      onTap: () {
                        chatController.translateMessage(message, lang['code']!,
                            messageId: messageId);
                        Navigator.pop(ctx);
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
