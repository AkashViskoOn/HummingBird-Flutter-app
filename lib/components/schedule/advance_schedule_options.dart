import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AdvanceScheduleOptions extends StatelessWidget {
  const AdvanceScheduleOptions({super.key});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return Obx(
      () => Card(
        elevation: chatController.scheduleCount.value == 0 ? 1 : 5,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.fifteen.r)),
        shadowColor: Colors.grey.withValues(alpha: 0.5), // Adjust the
        child: TextButton(
          onPressed: () {
            chatController.scheduleCount.value = 0;
          },
          style: TextButton.styleFrom(
              backgroundColor: CustomColor.k2LightsecondaryColor,
              fixedSize: Size(Get.width * 0.4, 45.h),
              overlayColor: Colors.grey[400],
              shape: RoundedRectangleBorder(
                  // side: const BorderSide(
                  //     color: Colors.black, width: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.fifteen.r))),
          child: Text(
            'Forever',
            style: TextStyle(fontSize: 18.sp),
          ),
        ),
      ),
    );
  }
}
