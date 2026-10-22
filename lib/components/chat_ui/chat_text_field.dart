import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';

class ChatTextField extends StatefulWidget {
  const ChatTextField({super.key});

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  ChatController chatController = Get.find();

  @override
  void initState() {
    chatController.previewController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: CustomColor.kPrimaryColor,
      controller: chatController.previewController,
      keyboardType: TextInputType.multiline,
      minLines: 1,
      maxLines: 3,
      style: AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextOnDark),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(top: AppSpacing.xl.h),
        hintText: 'Type a message...',
        hintStyle:
            AppTextStyles.headingSm.copyWith(color: CustomColor.kOverlay60),
        filled: true,
        fillColor: CustomColor.kOverlay12,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.4),
              width: 1.5),
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: CustomColor.kPrimaryColor, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
        ),
        prefixIcon: IconButton(
          tooltip: 'Emoji',
          onPressed: () {},
          icon: Icon(
            Icons.emoji_emotions_outlined,
            size: AppIcons.xxxl,
            color: CustomColor.kPrimaryLight,
          ),
        ),
      ),
    );
  }
}
