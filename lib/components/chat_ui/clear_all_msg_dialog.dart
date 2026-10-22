import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';

class DeleteAllMessagesDialog extends StatelessWidget {
  final String roomId;
  const DeleteAllMessagesDialog({super.key, required this.roomId});

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
                  ' Delete All Messages',
                  style: AppTextStyles.headingXl
                      .copyWith(color: CustomColor.kDarkPrimaryColor),
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
                    const Flexible(
                      child: Text('Also delete all media from device'),
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
                          chatController.deleteAllMessage(
                              roomId, chatController.deleteRoomMedia.value);
                        },
                        child: Text(
                          'Delete Messages',
                          style: AppTextStyles.headingSm
                              .copyWith(color: CustomColor.kDarkDangerColor),
                        )),
                  ],
                )
              ],
            ),
          ),
          IconButton(
              tooltip: 'Cancel',
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.cancel,
                color: Colors.grey,
                size: AppIcons.xxxl.r,
              ))
        ],
      ),
    );
  }
}
