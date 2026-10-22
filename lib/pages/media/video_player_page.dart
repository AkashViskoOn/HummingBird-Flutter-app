import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/chat_ui/message_action_sheet.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class VideoPlayerPage extends StatefulWidget {
  final String? videoUrl;
  final File? videoFile;
  final String? title;
  final String? messageId;

  const VideoPlayerPage({
    super.key,
    this.videoUrl,
    this.videoFile,
    this.title,
    this.messageId,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeFuture;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  bool _isLocked = false;
  bool _hasError = false;
  Timer? _controlsTimer;
  Messages? _message;
  bool _isGroup = false;

  @override
  void initState() {
    super.initState();
    _initializeFuture = _initController();
    _loadMessage();
  }

  void _loadMessage() {
    final messageId = widget.messageId;
    if (messageId == null || messageId.isEmpty) return;
    final message = LocalDatabase.getSingleMessages(messageId);
    _message = message;
    if (message?.mRoomId != null) {
      final room =
          LocalDatabase.getRooms().where((r) => r.rId == message!.mRoomId);
      if (room.isNotEmpty) _isGroup = room.first.rType == '1';
    }
  }

  void _showActions() {
    final message = _message;
    if (message == null) return;
    MessageActionSheet.show(
      context: Get.context!,
      message: message,
      isMe: message.me == true,
      roomId: message.mRoomId ?? '',
      receiverId: message.mReceiverId ?? '',
      roomUsers: message.mRoomId ?? '',
      name: message.mReceiver ?? '',
      userNumber: '',
      userBio: '',
      userProfile: '',
      isGroup: _isGroup,
    );
  }

  Future<void> _initController() async {
    try {
      if (widget.videoFile != null) {
        _controller = VideoPlayerController.file(widget.videoFile!);
      } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(
            Uri.parse(AppHelper.resolveMediaUrl(widget.videoUrl!)));
      } else {
        throw StateError('No video source provided');
      }
      await _controller.initialize();
      _controller.addListener(() {
        if (mounted) setState(() {});
      });
      await _controller.play();
    } catch (e) {
      _hasError = true;
    }
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _skipForward() {
    final pos = _controller.value.position;
    final newPos = pos + const Duration(seconds: 10);
    _controller.seekTo(newPos > _controller.value.duration
        ? _controller.value.duration
        : newPos);
  }

  void _skipBackward() {
    final pos = _controller.value.position;
    final newPos = pos - const Duration(seconds: 10);
    _controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
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
      _controller.setPlaybackSpeed(_playbackSpeed);
    });
  }

  Future<void> _downloadVideo() async {
    if (widget.videoUrl == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final file = File('${dir.path}/$fileName');
      final url = AppHelper.resolveMediaUrl(widget.videoUrl);
      final dio = Dio();
      await dio.download(url, file.path);
      CustomSnackbar.success(
          title: 'Downloaded', message: 'Video saved successfully');
    } catch (e) {
      CustomSnackbar.error(title: 'Error', message: 'Failed to download video');
    }
  }

  Future<void> _shareVideo() async {
    try {
      if (widget.videoFile != null) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(widget.videoFile!.path)]),
        );
      }
    } catch (_) {}
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    try {
      _controller.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _retry() {
    setState(() => _hasError = false);
    _initializeFuture = _initController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasError ? _buildError() : _buildPlayer(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: CustomColor.kOverlay38, size: 56),
          SizedBox(height: 16.h),
          Text('Could not play this video',
              style:
                  AppTextStyles.bodyMd.copyWith(color: CustomColor.kOverlay70)),
          SizedBox(height: 20.h),
          GestureDetector(
            onTap: _retry,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryColor,
                borderRadius: BorderRadius.circular(AppRadius.rounded.r),
              ),
              child: Text('Retry',
                  style: AppTextStyles.titleSm
                      .copyWith(color: CustomColor.kTextOnDark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return FutureBuilder(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              color: CustomColor.kPrimaryColor,
            ),
          );
        }
        return Stack(
          children: [
            GestureDetector(
              onTap: _toggleControls,
              child: Center(
                child: _controller.value.isInitialized
                    ? VideoPlayer(_controller)
                    : const SizedBox.shrink(),
              ),
            ),
            if (_controller.value.isBuffering &&
                _controller.value.isInitialized)
              const Center(
                child: CircularProgressIndicator(
                  color: CustomColor.kPrimaryColor,
                ),
              ),
            if (_showControls) _buildControls(),
            if (!_isLocked)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8.h,
                left: 8.w,
                child: const AppBackButton(color: CustomColor.kTextOnDark),
              ),
            if (!_isLocked)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8.h,
                right: 8.w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Download video',
                      icon: Icon(Icons.download_rounded,
                          color: CustomColor.kTextOnDark, size: 24.sp),
                      onPressed: _downloadVideo,
                    ),
                    IconButton(
                      icon: Icon(Icons.share_rounded,
                          color: CustomColor.kTextOnDark, size: 24.sp),
                      onPressed: _shareVideo,
                    ),
                    IconButton(
                      tooltip: 'Lock screen',
                      icon: Icon(
                        _isLocked
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: CustomColor.kTextOnDark,
                        size: 24.sp,
                      ),
                      onPressed: () => setState(() => _isLocked = !_isLocked),
                    ),
                    if (_message != null)
                      IconButton(
                        tooltip: 'More options',
                        icon: Icon(Icons.more_vert_rounded,
                            color: CustomColor.kTextOnDark, size: 24.sp),
                        onPressed: _showActions,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    final value = _controller.value;
    final duration = value.duration;
    final position = value.position;
    final isPlaying = value.isPlaying;

    return Positioned(
      left: 0.w,
      right: 0.w,
      bottom: 0.h,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              _controller,
              allowScrubbing: !_isLocked,
              colors: const VideoProgressColors(
                playedColor: CustomColor.kPrimaryColor,
                bufferedColor: CustomColor.kOverlay24,
                backgroundColor: CustomColor.kOverlay8,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kOverlay70),
                ),
                Text(
                  _formatDuration(duration),
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kOverlay70),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Rewind 10 seconds',
                  icon: Icon(Icons.replay_10_rounded,
                      color: CustomColor.kTextOnDark, size: 28.sp),
                  onPressed: _skipBackward,
                ),
                SizedBox(width: 20.w),
                Container(
                  decoration: BoxDecoration(
                    color: CustomColor.kTextOnDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    tooltip: 'Pause',
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: CustomColor.kTextOnDark,
                      size: 48.sp,
                    ),
                    onPressed: () {
                      isPlaying ? _controller.pause() : _controller.play();
                    },
                  ),
                ),
                SizedBox(width: 20.w),
                IconButton(
                  tooltip: 'Forward 10 seconds',
                  icon: Icon(Icons.forward_10_rounded,
                      color: CustomColor.kTextOnDark, size: 28.sp),
                  onPressed: _skipForward,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _cycleSpeed,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.sm.r),
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: AppTextStyles.bodySm
                          .copyWith(color: CustomColor.kPrimaryColor),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                GestureDetector(
                  onTap: () {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: CustomColor.kTextOnDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm.r),
                    ),
                    child: Text(
                      isPlaying ? 'Pause' : 'Play',
                      style: AppTextStyles.bodySm
                          .copyWith(color: CustomColor.kOverlay70),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
