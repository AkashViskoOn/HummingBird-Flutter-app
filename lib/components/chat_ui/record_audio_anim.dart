import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:lottie/lottie.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';

class RecordAudioAnim extends StatelessWidget {
  final bool fromScheduleScreen;
  const RecordAudioAnim({super.key, this.fromScheduleScreen = true});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.rounded.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.r, vertical: AppSpacing.xxxl.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(AppAssets.audioAnim, width: Get.width * 0.6),
            SizedBox(
              height: AppSpacing.xl.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton(
                  text: 'Cancel',
                  onTap: () {
                    chatController.disposeRecorder();
                    Get.back();
                  },
                  buttonSize: Size(Get.width * 0.35, 45.h),
                  backgroundColor:
                      CustomColor.kTextTertiary.withValues(alpha: 0.2),
                ),
                AppButton(
                  text: 'Send',
                  onTap: () {
                    chatController.saveAudio(
                        fromScheduleScreen: fromScheduleScreen);
                    Get.back();
                  },
                  buttonSize: Size(Get.width * 0.35, 45.h),
                  backgroundColor: CustomColor.kPrimaryFill,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
