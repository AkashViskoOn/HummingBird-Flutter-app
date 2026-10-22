import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';

class VideoButtonContainer extends StatelessWidget {
  final UniqueKey videoKey;
  const VideoButtonContainer({super.key, required this.videoKey});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return Obx(() => AnimatedOpacity(
          opacity:
              chatController.isVideoPlayingMap[videoKey] != true ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Visibility(
            visible: chatController.isVideoPlayingMap[videoKey] != true,
            child: Container(
              width: 50.r,
              height: 50.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
              ),
              child: Icon(
                chatController.isVideoPlayingMap[videoKey] == true
                    ? Icons.pause
                    : Icons.play_arrow_rounded,
                size: 30.r,
                color: CustomColor.kPrimaryColor,
              ),
            ),
          ),
        ));
  }
}
