import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';

class DeleteRoomDialog extends StatelessWidget {
  final String roomId;
  final bool fromUserInfo;
  const DeleteRoomDialog(
      {super.key, required this.roomId, this.fromUserInfo = false});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return Dialog(
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: Get.width * 0.8,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xxxl.r)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ' Delete Chat',
                  style: AppTextStyles.headingXl,
                ),
                SizedBox(
                  height: Get.height * 0.02,
                ),
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                        value: chatController.deleteRoomMedia.value,
                        onChanged: (value) {
                          chatController.deleteRoomMedia.value = value ?? false;
                        },
                      ),
                    ),
                    Flexible(
                      child: Text('Also delete chat media from device',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: CustomColor.kTextSecondary)),
                    )
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.headingSm
                              .copyWith(color: CustomColor.kTextSecondary),
                        )),
                    TextButton(
                        onPressed: () {
                          chatController.deleteRoom(
                              roomId,
                              chatController.deleteRoomMedia.value,
                              fromUserInfo);
                        },
                        child: Text(
                          'Delete Chat',
                          style: AppTextStyles.headingSm
                              .copyWith(color: CustomColor.kDangerRed),
                        )),
                  ],
                )
              ],
            ),
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.close_rounded,
                color: CustomColor.kTextTertiary,
                size: AppIcons.xxl.r,
              ),
            ),
          )
        ],
      ),
    );
  }
}
