import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:video_player/video_player.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class StatusVideoEditor extends StatefulWidget {
  final File videoFile;
  final String? initialCaption;

  const StatusVideoEditor({
    super.key,
    required this.videoFile,
    this.initialCaption,
  });

  @override
  State<StatusVideoEditor> createState() => _StatusVideoEditorState();
}

class _StatusVideoEditorState extends State<StatusVideoEditor> {
  late VideoPlayerController _controller;
  final TextEditingController _captionCtrl = TextEditingController();
  final StatusController _statusCtrl = Get.find();
  bool _isUploading = false;
  bool _isMuted = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile);
    _controller.initialize().then((_) {
      setState(() => _initialized = true);
      _controller.setLooping(true);
      _controller.play();
    });
  }

  Future<void> _share() async {
    setState(() => _isUploading = true);
    try {
      final result = await _statusCtrl.createUpdate(
        _captionCtrl.text,
        file: widget.videoFile,
        mediaType: 'video',
      );
      if (result != null) {
        Get.back();
        Get.back();
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CommonAppBar(
        title: '',
        backgroundColor: Colors.black,
        showBackButton: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, color: CustomColor.kTextOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isUploading
              ? Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const CircularProgressIndicator(
                      color: CustomColor.kTextOnDark))
              : TextButton(
                  onPressed: _share,
                  child: Text('Share',
                      style: GoogleFonts.poppins(
                          color: CustomColor.kTextOnDark,
                          fontWeight: FontWeight.w600)),
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _initialized
                  ? GestureDetector(
                      onTap: () {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                          if (!_controller.value.isPlaying)
                            Icon(Icons.play_circle,
                                color: CustomColor.kOverlay70, size: 64.r),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(
                      color: CustomColor.kTextOnDark),
            ),
          ),
          // Controls
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.grey[900],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlButton(Icons.content_cut_rounded, 'Trim', () {}),
                    _controlButton(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      _isMuted ? 'Unmute' : 'Mute',
                      () => setState(() {
                        _isMuted = !_isMuted;
                        _controller.setVolume(_isMuted ? 0 : 1);
                      }),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                if (_initialized)
                  VideoProgressIndicator(_controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: CustomColor.kPrimaryColor,
                        bufferedColor: CustomColor.kOverlay24,
                        backgroundColor: CustomColor.kOverlay12,
                      )),
                SizedBox(height: 8.h),
                TextField(
                  controller: _captionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: GoogleFonts.poppins(
                        color: CustomColor.kTextOnDarkSecondary),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: CustomColor.kOverlay12,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  style: AppTextStyles.bodyMd
                      .copyWith(color: CustomColor.kTextOnDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: CustomColor.kTextOnDark, size: 20.r),
          ),
          SizedBox(height: 4.h),
          Text(label,
              style: AppTextStyles.labelSm
                  .copyWith(color: CustomColor.kOverlay60)),
        ],
      ),
    );
  }
}
