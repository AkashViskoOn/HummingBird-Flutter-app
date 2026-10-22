import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/media/video_player_page.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/theme/app_radius.dart';

class VideoViewWidget extends StatelessWidget {
  final String videoUrl;
  final String mediaId;
  final String roomId;
  final String videoKey;
  final String? messageId;

  const VideoViewWidget({
    super.key,
    required this.videoUrl,
    required this.mediaId,
    required this.roomId,
    required this.videoKey,
    this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final birdController = Get.find<BirdController>();
    final fullUrl = AppHelper.resolveMediaUrl(videoUrl);

    return Obx(() {
      final isDownloading = birdController.downloadingMediaMap[mediaId] == true;
      final downloadProgress =
          birdController.downloadingMediaMap['${mediaId}_progress'];
      final savedMedia = LocalDatabase.getMedia(mediaId);
      final localFile = savedMedia?.mediaPath?.isNotEmpty == true
          ? File(savedMedia!.mediaPath!)
          : null;

      return Container(
        width: 220.w,
        height: 160.h,
        decoration: BoxDecoration(
          color: CustomColor.kDarkSurface,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          border: Border.all(
            color: CustomColor.kTextOnDark.withValues(alpha: 0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.14),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
              child: Container(
                width: 220.w,
                height: 158.h,
                color: CustomColor.kDarkSurface2,
                child: Center(
                  child: Icon(Icons.videocam_rounded,
                      color: CustomColor.kOverlay54, size: 48.sp),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
              ),
            ),
            if (isDownloading)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: CustomColor.kPrimaryColor,
                    strokeWidth: 2,
                  ),
                  if (downloadProgress is double)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        '${(downloadProgress * 100).toInt()}%',
                        style: TextStyle(
                          color: CustomColor.kTextOnDark,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                ],
              )
            else
              GestureDetector(
                onTap: () {
                  if (savedMedia != null) {
                    Get.to(() => VideoPlayerPage(
                          videoFile: localFile,
                          videoUrl: fullUrl,
                          title: videoKey,
                          messageId: messageId,
                        ));
                  } else {
                    chatController.downloadMedia(fullUrl, mediaId, roomId, '4');
                  }
                },
                child: Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kScrim60,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    savedMedia != null
                        ? Icons.play_arrow_rounded
                        : Icons.download_rounded,
                    color: CustomColor.kTextOnDark,
                    size: 28.r,
                  ),
                ),
              ),
            if (isDownloading && downloadProgress is double)
              Positioned(
                left: 0.w,
                right: 0.w,
                bottom: 0.h,
                child: LinearProgressIndicator(
                  value: downloadProgress.clamp(0.0, 1.0),
                  backgroundColor:
                      CustomColor.kPrimaryColor.withValues(alpha: 0.2),
                  color: CustomColor.kPrimaryColor,
                  minHeight: 3,
                ),
              ),
          ],
        ),
      );
    });
  }
}
