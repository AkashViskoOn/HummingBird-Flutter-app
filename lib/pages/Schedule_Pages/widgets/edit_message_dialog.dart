import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/app_textfield.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class EditMessageDialog extends StatefulWidget {
  final Messages currentMessage;
  const EditMessageDialog({super.key, required this.currentMessage});

  @override
  State<EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late ChatController chatController;

  @override
  void initState() {
    chatController = Get.find();
    chatController.textMessageController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    chatController.textMessageController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 24.r),
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
          borderRadius: BorderRadius.circular(AppRadius.rounded.r),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      gradient: CustomColor.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: CustomColor.kTextOnDark,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Edit Message',
                    style: AppTextStyles.headingMd.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              AppTextField(
                controller: chatController.textMessageController
                  ..text = widget.currentMessage.mMessage.toString(),
                hintText: '',
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  AppButton(
                    text: 'Cancel',
                    onTap: () => Get.back(),
                    buttonSize: Size(Get.width * 0.3, 45.h),
                  ),
                  AppButton(
                    text: 'Save',
                    onTap: () => chatController.editMessageFromScheduleScreen(
                        widget.currentMessage,
                        chatController.textMessageController.text.trim()),
                    buttonSize: Size(Get.width * 0.3, 45.h),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
