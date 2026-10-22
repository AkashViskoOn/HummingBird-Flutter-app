import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  WaveformPainter({
    required this.amplitudes,
    required this.progress,
    this.playedColor = CustomColor.kPrimaryColor,
    this.unplayedColor = CustomColor.kPrimaryLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    final barWidth = size.width / amplitudes.length;
    final midY = size.height / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final amp = amplitudes[i] * size.height / 2;
      final x = i * barWidth;
      final isPlayed = i / amplitudes.length <= progress;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x + 1, midY - amp, x + barWidth - 1, midY + amp),
          Radius.circular(2.r),
        ),
        Paint()
          ..color = isPlayed ? playedColor : unplayedColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.amplitudes != amplitudes;
}

class VoiceMessageWidget extends StatefulWidget {
  final String mediaUrl;
  final String mediaId;
  final String roomId;
  final String audioKey;

  const VoiceMessageWidget({
    super.key,
    required this.mediaUrl,
    required this.mediaId,
    required this.roomId,
    required this.audioKey,
  });

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  double _playbackSpeed = 1.0;
  late List<double> _waveformBars;
  late final UniqueKey _playKey;

  @override
  void initState() {
    super.initState();
    _waveformBars = _generateWaveform();
    _playKey = UniqueKey();
  }

  List<double> _generateWaveform() {
    final random = Random(widget.mediaId.hashCode);
    return List.generate(40, (_) => 0.15 + random.nextDouble() * 0.85);
  }

  void _cycleSpeed() {
    setState(() {
      if (_playbackSpeed >= 2.0) {
        _playbackSpeed = 0.5;
      } else if (_playbackSpeed >= 1.5) {
        _playbackSpeed = 2.0;
      } else if (_playbackSpeed >= 1.0) {
        _playbackSpeed = 1.5;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    Get.find<ChatController>().setPlaybackSpeed(_playbackSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final birdController = Get.find<BirdController>();
    final fullUrl = AppHelper.resolveMediaUrl(widget.mediaUrl);
    final playKey = _playKey;

    return Container(
      width: 0.7.sw,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        border: Border.all(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final isPlaying = chatController.isAudioPlayingMap[playKey] == true;
        final isDownloading =
            birdController.downloadingMediaMap[widget.mediaId] == true;
        final downloadProgress =
            birdController.downloadingMediaMap['${widget.mediaId}_progress'] ??
                0.0;
        final savedMedia = LocalDatabase.getMedia(widget.mediaId);
        final progress = chatController.audioCurrentPosition.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (isDownloading) {
                      chatController.cancelDownload(widget.mediaId);
                      return;
                    }
                    if (savedMedia != null) {
                      if (isPlaying) {
                        chatController.pauseAudio(playKey);
                      } else {
                        chatController.playRecordedAudio(
                            playKey, widget.mediaId);
                      }
                    } else {
                      chatController.downloadMedia(
                          fullUrl, widget.mediaId, widget.roomId, '3');
                    }
                  },
                  child: Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: const BoxDecoration(
                      color: CustomColor.kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: isDownloading
                        ? Padding(
                            padding: EdgeInsets.all(9.r),
                            child: CircularProgressIndicator(
                              color: CustomColor.kTextOnDark,
                              strokeWidth: 2,
                              value: (downloadProgress is double)
                                  ? downloadProgress.clamp(0.0, 1.0)
                                  : null,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: CustomColor.kTextOnDark,
                            size: 22.r,
                          ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: GestureDetector(
                    onTapUp: (details) {
                      if (savedMedia == null) return;
                      if (chatController.audioDuration == null) return;
                      final box = context.findRenderObject() as RenderBox;
                      final localPos = details.localPosition;
                      final totalWidth = box.size.width - 56.w;
                      final tappedX = localPos.dx - 56.w;
                      final ratio = (tappedX / totalWidth).clamp(0.0, 1.0);
                      chatController.seekAudio(ratio *
                          chatController.audioDuration!.inMilliseconds
                              .toDouble());
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 30.h,
                          child: CustomPaint(
                            size: Size(180.w, 30.h),
                            painter: WaveformPainter(
                              amplitudes: _waveformBars,
                              progress: progress.clamp(0.0, 1.0),
                              unplayedColor: CustomColor.kLightBorder,
                            ),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Text(
                              chatController.audioCurrentPositionString.value,
                              style: AppTextStyles.labelSm
                                  .copyWith(color: CustomColor.kTextSecondary),
                            ),
                            const Spacer(),
                            if (chatController.audioDuration != null)
                              Text(
                                AppHelper.formatDuration(
                                    chatController.audioDuration!),
                                style: AppTextStyles.labelSm.copyWith(
                                    color: CustomColor.kTextSecondary),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                GestureDetector(
                  onTap: _cycleSpeed,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm.r),
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: AppTextStyles.labelSm
                          .copyWith(color: CustomColor.kPrimaryColor),
                    ),
                  ),
                ),
              ],
            ),
            if (isDownloading && downloadProgress is double)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: LinearProgressIndicator(
                  value: downloadProgress.clamp(0.0, 1.0),
                  backgroundColor:
                      CustomColor.kPrimaryColor.withValues(alpha: 0.15),
                  color: CustomColor.kPrimaryColor,
                  minHeight: 2,
                ),
              ),
          ],
        );
      }),
    );
  }
}
