import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/common/widgets/image_error_placeholder.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class StatusMediaEditorScreen extends StatefulWidget {
  final File mediaFile;
  final String mediaType; // image | video
  final List<File>? queueFiles;

  const StatusMediaEditorScreen({
    super.key,
    required this.mediaFile,
    required this.mediaType,
    this.queueFiles,
  });

  @override
  State<StatusMediaEditorScreen> createState() =>
      _StatusMediaEditorScreenState();
}

class _StatusMediaEditorScreenState extends State<StatusMediaEditorScreen>
    with SingleTickerProviderStateMixin {
  late File _currentFile;
  VideoPlayerController? _videoController;
  final TextEditingController _captionCtrl = TextEditingController();
  final GlobalKey _captureKey = GlobalKey();

  int _rotation = 0;
  final List<ui.Offset> _strokePoints = [];
  final List<_EmojiSticker> _stickers = [];
  bool _drawingMode = false;
  int _queueIndex = 0;
  bool _isUploading = false;

  static const _stickerEmojis = [
    '😀',
    '😂',
    '😍',
    '😎',
    '🔥',
    '❤️',
    '👍',
    '🎉',
    '✨',
    '🥳',
    '💯',
    '🤩'
  ];

  StatusController get _statusCtrl => Get.find();

  @override
  void initState() {
    super.initState();
    _currentFile = widget.mediaFile;
    if (widget.mediaType == 'video') {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.file(_currentFile);
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  List<File> get _queue => widget.queueFiles ?? [_currentFile];

  Future<void> _cropImage() async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: _currentFile.path,
        // aspectRatioPresets: [
        //   CropAspectRatioPreset.square,
        //   CropAspectRatioPreset.ratio3x4,
        //   CropAspectRatioPreset.ratio4x3,
        //   CropAspectRatioPreset.ratio16x9,
        //   CropAspectRatioPreset.original,
        // ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Status',
            toolbarColor: CustomColor.kPrimaryColor,
            toolbarWidgetColor: CustomColor.kTextOnDark,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Status'),
        ],
      );
      if (cropped != null) {
        setState(() {
          _currentFile = File(cropped.path);
          _rotation = 0;
        });
      }
    } catch (_) {}
  }

  Future<File?> _bakeComposite() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/status_composite_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareCurrent() async {
    setState(() => _isUploading = true);
    try {
      final file = _currentFile;
      final caption = _captionCtrl.text.trim();
      final result = await _statusCtrl.createUpdate(
        caption.isEmpty ? 'Shared a ${widget.mediaType} status' : caption,
        file: file,
        mediaType: widget.mediaType,
        caption: caption.isEmpty ? null : caption,
      );
      if (result != null && _queueIndex < _queue.length - 1) {
        setState(() {
          _queueIndex++;
          _currentFile = _queue[_queueIndex];
          _rotation = 0;
          _strokePoints.clear();
          _stickers.clear();
          _captionCtrl.clear();
        });
        if (widget.mediaType == 'video') {
          await _initVideo();
        }
        setState(() => _isUploading = false);
        return;
      }
      if (result != null) {
        Get.back();
        CustomSnackbar.success(title: 'Success', message: 'Status shared');
      } else {
        CustomSnackbar.error(
            title: 'Failed', message: 'Could not share status');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _shareAll() async {
    if (widget.mediaType == 'video') {
      await _shareCurrent();
      return;
    }
    if (_strokePoints.isNotEmpty || _stickers.isNotEmpty || _rotation != 0) {
      final baked = await _bakeComposite();
      if (baked != null) {
        setState(() => _currentFile = baked);
      }
    }
    await _shareCurrent();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.mediaType == 'video';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CommonAppBar(
        title: _queue.length > 1
            ? 'Status ${_queueIndex + 1}/${_queue.length}'
            : 'Status',
        backgroundColor: Colors.black,
        showBackButton: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded, color: CustomColor.kTextOnDark),
          onPressed: () => Get.back(),
        ),
        actions: [
          _isUploading
              ? Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const CircularProgressIndicator(
                      color: CustomColor.kTextOnDark, strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _shareAll,
                  child: Text(
                    'Share',
                    style: AppTextStyles.titleMd
                        .copyWith(color: CustomColor.kTextOnDark),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onLongPressStart: (d) {
                  if (isVideo) return;
                  setState(() {
                    _drawingMode = true;
                    _strokePoints.add(d.localPosition);
                  });
                },
                onLongPressMoveUpdate: (d) {
                  if (isVideo || !_drawingMode) return;
                  setState(() => _strokePoints.add(d.localPosition));
                },
                onLongPressEnd: (_) => setState(() => _drawingMode = false),
                child: RepaintBoundary(
                  key: _captureKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.black),
                      Center(
                        child: Transform.rotate(
                          angle: _rotation * 3.14159265358979 / 2,
                          child: isVideo
                              ? _buildVideoPreview()
                              : Image.file(
                                  _currentFile,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      const ImageErrorPlaceholder(),
                                ),
                        ),
                      ),
                      if (!isVideo)
                        CustomPaint(
                          size: Size.infinite,
                          painter: _StrokePainter(_strokePoints),
                        ),
                      ..._stickers.map((s) => Positioned(
                            left: s.position.dx - 24.r,
                            top: s.position.dy - 24.r,
                            child: GestureDetector(
                              onPanUpdate: (d) {
                                setState(() {
                                  s.position = Offset(
                                    s.position.dx + d.delta.dx,
                                    s.position.dy + d.delta.dy,
                                  );
                                });
                              },
                              child: Text(s.emoji,
                                  style: TextStyle(fontSize: 34.sp)),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
            _buildToolbar(isVideo),
            _buildCaptionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const CircularProgressIndicator(color: CustomColor.kTextOnDark);
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _videoController!.value.size.width,
        height: _videoController!.value.size.height,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildToolbar(bool isVideo) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!isVideo)
            _ToolButton(
              icon: Icons.crop_rounded,
              label: 'Crop',
              onTap: _cropImage,
            ),
          _ToolButton(
            icon: Icons.rotate_right_rounded,
            label: 'Rotate',
            onTap: () => setState(() => _rotation = (_rotation + 1) % 4),
          ),
          if (!isVideo)
            _ToolButton(
              icon: Icons.brush_rounded,
              label: 'Draw',
              onTap: () => setState(() {
                _drawingMode = !_drawingMode;
                if (!_drawingMode) {
                  _strokePoints.clear();
                }
              }),
            ),
          _ToolButton(
            icon: Icons.emoji_emotions_rounded,
            label: 'Sticker',
            onTap: _showStickerPicker,
          ),
        ],
      ),
    );
  }

  void _showStickerPicker() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl.r)),
        ),
        child: SafeArea(
          top: false,
          child: Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: _stickerEmojis.map((e) {
              return GestureDetector(
                onTap: () {
                  Get.back();
                  setState(() {
                    _stickers.add(_EmojiSticker(
                      emoji: e,
                      position: Offset(
                        MediaQuery.of(context).size.width / 2,
                        MediaQuery.of(context).size.height / 2 - 120.h,
                      ),
                    ));
                  });
                },
                child: Text(e, style: TextStyle(fontSize: 30.sp)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _captionCtrl,
              style:
                  AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextOnDark),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: AppTextStyles.bodyMd
                    .copyWith(color: CustomColor.kOverlay38),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<ui.Offset> points;
  _StrokePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 5.r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _EmojiSticker {
  final String emoji;
  Offset position;
  _EmojiSticker({required this.emoji, required this.position});
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: CustomColor.kTextOnDark, size: 20.r),
          SizedBox(height: 2.h),
          Text(
            label,
            style:
                AppTextStyles.labelSm.copyWith(color: CustomColor.kOverlay70),
          ),
        ],
      ),
    );
  }
}
