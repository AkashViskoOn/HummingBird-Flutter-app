import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/common/widgets/video_button.dart';
import 'package:humming_bird/components/chat_ui/chat_text_field.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_icons.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File videoFile;
  final bool isScheduled;
  const VideoPreviewScreen(
      {super.key, required this.videoFile, this.isScheduled = false});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController videoController;
  late Future<void> isVideoReady;
  final BirdController birdController = Get.find();
  bool videoPlaying = false;
  UniqueKey videoKey = UniqueKey();

  @override
  void initState() {
    isVideoReady = initVideoController();
    super.initState();
  }

  Future<void> initVideoController() async {
    try {
      videoController = VideoPlayerController.file(widget.videoFile);
      await videoController.initialize();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Video init error: $e');
      }
    }
  }

  void playPauseVideo() {
    try {
      videoPlaying ? videoController.pause() : videoController.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      videoController.dispose();
    } catch (_) {}
    super.dispose();
  }

  ChatController chatController = Get.find();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: CustomColor.kDarkSecondaryColor,
      body: Entrance(
        fade: true,
        slide: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.w, vertical: AppSpacing.lg.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(color: CustomColor.kTextOnDark),
              const Spacer(),
              FutureBuilder(
                future: isVideoReady,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        InkWell(
                          onTap: () {
                            playPauseVideo();
                            chatController.playPauseVideo(videoKey);
                            videoPlaying = !videoPlaying;
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                  height: Get.height * 0.3,
                                  width: Get.width * 0.4,
                                  child: VideoPlayer(videoController)),
                              VideoButtonContainer(
                                videoKey: videoKey,
                              )
                            ],
                          ),
                        ),
                        VideoProgressIndicator(
                          videoController,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                              backgroundColor: CustomColor.kTextOnDark,
                              bufferedColor: Colors.grey,
                              playedColor: Colors.redAccent),
                        )
                      ],
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                },
              ),
              const Spacer(),
              Row(
                children: [
                  const Flexible(child: ChatTextField()),
                  SizedBox(
                    width: AppSpacing.xs.w,
                  ),
                  GestureDetector(
                      onTap: () {
                        chatController.sendMedia(
                            messageType: 4,
                            includeText: true,
                            isScheduled: widget.isScheduled);
                        Get.back();
                      },
                      child: Container(
                        padding: EdgeInsets.all(5.r),
                        decoration: const BoxDecoration(
                            color: CustomColor.k2LightsecondaryColor,
                            shape: BoxShape.circle),
                        child: Icon(Icons.send,
                            size: AppIcons.big.r,
                            color: CustomColor.kDarkPrimaryColor),
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
