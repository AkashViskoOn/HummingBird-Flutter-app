import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:video_player/video_player.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class VideoTrimmer extends StatefulWidget {
  final File videoFile;
  final void Function(double start, double end) onTrim;

  const VideoTrimmer({
    super.key,
    required this.videoFile,
    required this.onTrim,
  });

  static void show(
    BuildContext context, {
    required File videoFile,
    required void Function(double start, double end) onTrim,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoTrimmer(
        videoFile: videoFile,
        onTrim: onTrim,
      ),
    );
  }

  @override
  State<VideoTrimmer> createState() => _VideoTrimmerState();
}

class _VideoTrimmerState extends State<VideoTrimmer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeFuture;
  double _startPosition = 0.0;
  double _endPosition = 1.0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile);
    _initializeFuture = _controller.initialize().then((_) {
      _controller.addListener(() {
        if (_controller.value.isPlaying) {
          final pos = _controller.value.position.inMilliseconds /
              _controller.value.duration.inMilliseconds;
          if (pos >= _endPosition) {
            _controller.pause();
            _controller.seekTo(
              Duration(
                milliseconds:
                    (_startPosition * _controller.value.duration.inMilliseconds)
                        .toInt(),
              ),
            );
            setState(() => _isPlaying = false);
          }
        }
      });
    });
  }

  void _playTrimmed() {
    _controller.seekTo(
      Duration(
        milliseconds:
            (_startPosition * _controller.value.duration.inMilliseconds)
                .toInt(),
      ),
    );
    _controller.play();
    setState(() => _isPlaying = true);
  }

  void _applyTrim() {
    widget.onTrim(_startPosition, _endPosition);
    Get.back();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.75,
      decoration: BoxDecoration(
        color: CustomColor.kDarkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: FutureBuilder(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(
                color: CustomColor.kPrimaryColor,
              ),
            );
          }
          return Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CustomColor.kOverlay8,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: CustomColor.kTextOnDark.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Text('Trim Video',
                            style: AppTextStyles.headingMd
                                .copyWith(color: CustomColor.kTextOnDark)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _applyTrim,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: CustomColor.kPrimaryColor,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md.r),
                            ),
                            child: Text('Trim',
                                style: AppTextStyles.label
                                    .copyWith(color: CustomColor.kTextOnDark)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xl.r),
                            child: VideoPlayer(_controller),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: CustomColor.kOverlay8,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _buildRangeSlider(),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _isPlaying
                              ? () {
                                  _controller.pause();
                                  setState(() => _isPlaying = false);
                                }
                              : _playTrimmed,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: CustomColor.kPrimaryColor,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: CustomColor.kTextOnDark,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  _isPlaying ? 'Preview' : 'Preview Trim',
                                  style: AppTextStyles.titleSm
                                      .copyWith(color: CustomColor.kTextOnDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${_formatDuration(Duration(milliseconds: (_startPosition * _controller.value.duration.inMilliseconds).toInt()))} - ${_formatDuration(Duration(milliseconds: (_endPosition * _controller.value.duration.inMilliseconds).toInt()))}',
                      style: AppTextStyles.bodySm.copyWith(
                          color:
                              CustomColor.kTextOnDark.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRangeSlider() {
    return Column(
      children: [
        RangeSlider(
          values: RangeValues(_startPosition, _endPosition),
          min: 0.0,
          max: 1.0,
          divisions: 100,
          activeColor: CustomColor.kPrimaryColor,
          inactiveColor: CustomColor.kTextOnDark.withValues(alpha: 0.15),
          labels: RangeLabels(
            _formatDuration(Duration(
                milliseconds:
                    (_startPosition * _controller.value.duration.inMilliseconds)
                        .toInt())),
            _formatDuration(Duration(
                milliseconds:
                    (_endPosition * _controller.value.duration.inMilliseconds)
                        .toInt())),
          ),
          onChanged: (values) {
            setState(() {
              _startPosition = values.start;
              _endPosition = values.end;
            });
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
