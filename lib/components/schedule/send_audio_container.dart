import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class SendAudioContainer extends StatelessWidget {
  final String title;
  final Icon icon;
  const SendAudioContainer({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    BirdController birdController = Get.find();
    ChatController chatController = Get.find();
    return Container(
      width: Get.width * 0.4,
      height: Get.height * 0.09,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomColor.kPrimaryLight.withValues(alpha: 0.6),
            CustomColor.kTextOnDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(() =>
              chatController.uploadingFile.value && !chatController.uploadMedia
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: birdController.uploadValue.value,
                          color: CustomColor.kPrimaryColor,
                          strokeWidth: 2.5,
                        ),
                        Icon(
                          Icons.cloud_upload,
                          size: 25.r,
                          color: CustomColor.kPrimaryColor,
                        ),
                      ],
                    )
                  : icon),
          Text(
            title,
            style: AppTextStyles.titleMd
                .copyWith(color: CustomColor.kPrimaryColor),
          )
        ],
      ),
    );
  }
}
