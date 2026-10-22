import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/components/Models/media_model.dart';
import 'package:humming_bird/components/chat_ui/download_media_button.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AudioWidget extends StatelessWidget {
  final String audioUrl;
  final String audioId;
  final String roomId;
  final UniqueKey audioKey;
  const AudioWidget(
      {super.key,
      required this.audioUrl,
      required this.audioId,
      required this.roomId,
      required this.audioKey});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return Container(
      width: Get.width * 0.6,
      height: Get.height * 0.081,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
          color: CustomColor.kPrimaryLight,
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ]),
      child: GetBuilder<ChatController>(
          id: audioId,
          builder: (controller) {
            MediaModel? media = chatController.getMedia(audioId);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                media != null
                    ? Obx(
                        () => InkWell(
                          onTap: () {
                            chatController.isAudioPlayingMap[audioKey] == true
                                ? chatController.pauseAudio(audioKey)
                                : chatController.playRecordedAudio(
                                    audioKey, audioId);
                          },
                          child:
                              chatController.isAudioPlayingMap[audioKey] == true
                                  ? Icon(
                                      Icons.pause,
                                      size: 40.sp,
                                      color: CustomColor.kPrimaryColor,
                                    )
                                  : Icon(
                                      Icons.play_arrow_rounded,
                                      size: 45.sp,
                                      color: CustomColor.kPrimaryColor,
                                    ),
                        ),
                      )
                    : DownloadMediaButton(
                        mediaUrl: audioUrl,
                        mediaId: audioId,
                        roomId: roomId,
                        mediaType: '3',
                        iconColor: CustomColor.kPrimaryColor,
                      ),
                SizedBox(
                    width: Get.width * 0.44,
                    height: Get.height * 0.07,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.topRight,
                          children: [
                            Obx(() => Slider(
                                  value: chatController
                                              .isAudioPlayingMap[audioKey] ==
                                          true
                                      ? chatController
                                          .isAudioPlayingMap[audioId]
                                      : 0.0,
                                  onChanged: (value) {
                                    if (chatController.audioDuration != null) {
                                      chatController.seekAudio(value *
                                          chatController
                                              .audioDuration!.inMilliseconds);
                                    }
                                  },
                                  inactiveColor: CustomColor.kPrimaryLight,
                                  activeColor: CustomColor.kPrimaryColor,
                                  thumbColor: chatController
                                              .isAudioPlayingMap[audioKey] ==
                                          true
                                      ? CustomColor.kPrimaryColor
                                      : CustomColor.kTextOnDark,
                                )),
                            Obx(
                              () => Positioned(
                                bottom: -15,
                                right: 20.w,
                                child: chatController
                                            .isAudioPlayingMap[audioKey] ==
                                        true
                                    ? Text(
                                        chatController
                                            .audioCurrentPositionString.value,
                                        style: AppTextStyles.bodySm.copyWith(
                                            color: CustomColor.kTextTertiary),
                                      )
                                    : Text(
                                        '00:00',
                                        style: AppTextStyles.bodySm.copyWith(
                                            color: CustomColor.kTextTertiary),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
              ],
            );
          }),
    );
  }
}
