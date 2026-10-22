import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/common/widgets/blur_widget.dart';
import 'package:humming_bird/common/widgets/video_button.dart';
import 'package:humming_bird/components/chat_ui/download_media_button.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class VideoWidget extends StatefulWidget {
  final String videoUrl;
  final UniqueKey videoKey;
  final String mediaId;
  final String roomId;
  final String msg;
  const VideoWidget(
      {super.key,
      required this.videoUrl,
      required this.videoKey,
      required this.mediaId,
      required this.roomId,
      this.msg = ''});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;
  // chatController.downloadingMediaMap[widget.videoUrl] == true
  //     ? true
  //     : false;

  late VideoPlayerController videoController;
  late Future<void> isVideoReady;
  late File? videoFile;
  final BirdController birdController = Get.find();

  @override
  void initState() {
    isVideoReady = initVideoController();
    super.initState();
  }

  Future<void> initVideoController() async {
    videoFile = await chatController.initVideo(
        widget.mediaId, widget.videoUrl, widget.videoKey);
    if (videoFile != null) {
      videoController = VideoPlayerController.file(videoFile!);
      birdController.downloadingMediaMap[widget.videoUrl] = true;
    } else {
      videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    }
    return videoController.initialize();
  }

  @override
  void didUpdateWidget(covariant VideoWidget oldWidget) {
    if (birdController.downloadingMediaMap[widget.mediaId] != null) {
      isVideoReady = initVideoController();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  ChatController chatController = Get.find();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: Get.width * 0.6,
          height: Get.height * 0.25,
          child: FutureBuilder(
            future: isVideoReady,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: Get.height * 0.3,
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                );
              } else if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    InkWell(
                      onTap: () {
                        if (videoFile != null) {
                          chatController.isVideoPlayingMap[widget.videoKey] ==
                                  true
                              ? videoController.pause()
                              : videoController.play();
                          chatController.playPauseVideo(widget.videoKey);
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                              height: Get.height * 0.3,
                              width: Get.width * 0.4,
                              child: VideoPlayer(videoController)),
                          videoFile == null
                              ? const BlurWidget()
                              : const SizedBox.shrink(),
                          videoFile != null
                              ? VideoButtonContainer(
                                  videoKey: widget.videoKey,
                                )
                              : DownloadMediaButton(
                                  mediaUrl: widget.videoUrl,
                                  mediaId: widget.mediaId,
                                  roomId: widget.roomId,
                                  mediaType: '4',
                                  iconColor: CustomColor.kTextOnDark,
                                  iconSize: 50,
                                ),
                        ],
                      ),
                    ),
                    VideoProgressIndicator(
                      videoController,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                          backgroundColor:
                              CustomColor.kTextOnDark.withValues(alpha: 0.3),
                          bufferedColor:
                              CustomColor.kTextOnDark.withValues(alpha: 0.5),
                          playedColor: CustomColor.kPrimaryColor),
                    )
                  ],
                );
              } else {
                return const Center(
                  child: Text(
                    'Something went wrong, Can\'t load video',
                    style: TextStyle(color: CustomColor.kTextOnDark),
                  ),
                );
              }
            },
          ),
        ),
        widget.msg != ''
            ? Padding(
                padding: EdgeInsets.only(left: 5.r, bottom: 4.r, top: 4.r),
                child: Text(
                  widget.msg,
                  style: AppTextStyles.bodyLg
                      .copyWith(color: CustomColor.kTextPrimary),
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }
}
