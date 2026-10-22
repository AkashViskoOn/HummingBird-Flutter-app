import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/res/colors.dart';

class DownloadMediaButton extends StatelessWidget {
  final String mediaUrl;
  final String mediaId;
  final String roomId;
  final String mediaType;
  final Color? iconColor;
  final double? iconSize;

  const DownloadMediaButton(
      {super.key,
      required this.mediaUrl,
      required this.mediaId,
      required this.roomId,
      required this.mediaType,
      this.iconColor,
      this.iconSize});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    BirdController birdController = Get.find();
    return InkWell(
      onTap: () {
        chatController.downloadMedia(mediaUrl, mediaId, roomId, mediaType);
      },
      child: Container(
        width: Get.width * 0.1,
        height: Get.height * 0.04,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.thirty.r)),
        child: Obx(
          () => birdController.downloadingMediaMap[mediaId] == true
              ? CircularProgressIndicator.adaptive(
                  value:
                      birdController.downloadingMediaMap['${mediaId}_progress'],
                  backgroundColor: CustomColor.kTextOnDark,
                )
              : Icon(
                  Icons.download_for_offline_rounded,
                  size: iconSize ?? AppIcons.huge.r,
                  color: iconColor,
                ),
        ),
      ),
    );
  }
}
