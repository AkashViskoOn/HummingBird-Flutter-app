import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/image_viewer_widget.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ImageViewWidget extends StatelessWidget {
  final String imageUrl;
  final String mediaId;
  final String roomId;
  final String? messageId;

  const ImageViewWidget({
    super.key,
    required this.imageUrl,
    required this.mediaId,
    required this.roomId,
    this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    final birdController = Get.find<BirdController>();
    final fullUrl = AppHelper.resolveMediaUrl(imageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
      child: GetBuilder<ChatController>(
        id: mediaId,
        builder: (_) {
          final savedMedia = LocalDatabase.getMedia(mediaId);
          final isDownloading =
              birdController.downloadingMediaMap[mediaId] == true;
          final downloadProgress =
              birdController.downloadingMediaMap['${mediaId}_progress'];

          return SizedBox(
            width: 220.w,
            height: 180.h,
            child: Stack(
              children: [
                savedMedia != null
                    ? _SavedMediaImage(
                        imageUrl: fullUrl,
                        mediaId: mediaId,
                        roomId: roomId,
                        messageId: messageId,
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          _NetworkImageWithAutoDownload(
                            url: fullUrl,
                            mediaId: mediaId,
                            roomId: roomId,
                            messageId: messageId,
                          ),
                          Positioned(
                            right: 6.r,
                            bottom: 6.r,
                            child: _SaveImageButton(
                              mediaUrl: fullUrl,
                              mediaId: mediaId,
                              roomId: roomId,
                            ),
                          ),
                        ],
                      ),
                if (isDownloading)
                  Positioned(
                    left: 0.w,
                    right: 0.w,
                    bottom: 0.h,
                    child: LinearProgressIndicator(
                      value: (downloadProgress is double)
                          ? downloadProgress.clamp(0.0, 1.0)
                          : null,
                      backgroundColor:
                          CustomColor.kPrimaryColor.withValues(alpha: 0.2),
                      color: CustomColor.kPrimaryColor,
                      minHeight: 3,
                    ),
                  ),
                if (savedMedia != null)
                  Positioned(
                    top: 4.r,
                    left: 4.r,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppRadius.sm.r),
                      ),
                      child: Icon(
                        Icons.image_rounded,
                        color: CustomColor.kTextOnDark,
                        size: 14.r,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Loads the locally saved image bytes exactly once and keeps a stable
/// [MemoryImage] provider so list rebuilds never re-read the file or
/// re-decode the image (fixes spinner flicker and UI jank).
class _SavedMediaImage extends StatefulWidget {
  final String imageUrl;
  final String mediaId;
  final String roomId;
  final String? messageId;

  const _SavedMediaImage({
    required this.imageUrl,
    required this.mediaId,
    required this.roomId,
    this.messageId,
  });

  @override
  State<_SavedMediaImage> createState() => _SavedMediaImageState();
}

class _SavedMediaImageState extends State<_SavedMediaImage> {
  static final Map<String, Uint8List> _bytesCache = {};

  MemoryImage? _image;
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_SavedMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _image = null;
      _bytes = null;
      _load();
    }
  }

  Future<void> _load() async {
    final chatController = Get.find<ChatController>();
    setState(() {
      _loading = true;
      _image = null;
      _bytes = null;
    });

    final mediaModel = LocalDatabase.getMedia(widget.mediaId);
    if (mediaModel == null ||
        mediaModel.mediaPath == null ||
        !File(mediaModel.mediaPath!).existsSync()) {
      _bytesCache.remove(widget.mediaId);
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final cached = _bytesCache[widget.mediaId];
    if (cached != null && cached.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _bytes = cached;
        _image = MemoryImage(cached);
      });
      return;
    }

    final bytes = await chatController.getMediaFromPath(widget.mediaId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (bytes != null && bytes.isNotEmpty) {
        _bytesCache[widget.mediaId] = bytes;
        _bytes = bytes;
        _image = MemoryImage(bytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        width: 220.w,
        height: 180.h,
        color: CustomColor.kUltraLightBg,
        child: const Center(
          child: CircularProgressIndicator(
            color: CustomColor.kPrimaryColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final image = _image;
    final bytes = _bytes;
    if (image == null || bytes == null) {
      return _NetworkImageWithAutoDownload(
        url: widget.imageUrl,
        mediaId: widget.mediaId,
        roomId: widget.roomId,
        messageId: widget.messageId,
      );
    }

    return GestureDetector(
      onTap: () => Get.to(
        () => FullScreenImageView(
          url: widget.imageUrl,
          bytes: bytes,
          messageId: widget.messageId,
        ),
      ),
      child: Image(
        image: image,
        fit: BoxFit.cover,
        width: 220.w,
        height: 180.h,
        errorBuilder: (_, __, ___) => _NetworkImageWithAutoDownload(
          url: widget.imageUrl,
          mediaId: widget.mediaId,
          roomId: widget.roomId,
          messageId: widget.messageId,
        ),
      ),
    );
  }
}

class _NetworkImageWithAutoDownload extends StatefulWidget {
  final String url;
  final String mediaId;
  final String roomId;
  final String? messageId;

  const _NetworkImageWithAutoDownload({
    required this.url,
    required this.mediaId,
    required this.roomId,
    this.messageId,
  });

  @override
  State<_NetworkImageWithAutoDownload> createState() =>
      _NetworkImageWithAutoDownloadState();
}

class _NetworkImageWithAutoDownloadState
    extends State<_NetworkImageWithAutoDownload> {
  bool _autoDownloadFired = false;
  bool _autoRetried = false;
  int _attempt = 0;

  /// Fires a single background auto-download once per widget lifetime.
  /// Display never depends on it (assets load via CachedNetworkImage), so a
  /// failed save can't block the image from showing.
  void _autoDownload() {
    if (_autoDownloadFired) return;
    _autoDownloadFired = true;
    final birdController = Get.find<BirdController>();
    if (birdController.downloadingMediaMap[widget.mediaId] == true) return;
    final chatController = Get.find<ChatController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      chatController.downloadMedia(
        widget.url,
        widget.mediaId,
        widget.roomId,
        '1',
        showErrorSnackbar: false,
      );
    });
  }

  void _retryDownload() {
    final chatController = Get.find<ChatController>();
    chatController.downloadMedia(
      widget.url,
      widget.mediaId,
      widget.roomId,
      '1',
    );
  }

  @override
  void initState() {
    super.initState();
    _autoDownload();
  }

  @override
  Widget build(BuildContext context) {
    final isDownloading =
        Get.find<BirdController>().downloadingMediaMap[widget.mediaId] == true;
    return GestureDetector(
      onTap: () => Get.to(
        () => FullScreenImageView(
          url: widget.url,
          messageId: widget.messageId,
        ),
      ),
      child: CachedNetworkImage(
        key: ValueKey('img_retry_${_attempt}_${widget.mediaId}'),
        imageUrl: widget.url,
        width: 220.w,
        height: 180.h,
        fit: BoxFit.cover,
        memCacheWidth: 440,
        placeholder: (_, __) => Container(
          width: 220.w,
          height: 180.h,
          color: CustomColor.kUltraLightBg,
          child: const Center(
            child: CircularProgressIndicator(
              color: CustomColor.kPrimaryColor,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (_, __, ___) {
          if (!_autoRetried) {
            _autoRetried = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Future.delayed(const Duration(milliseconds: 1200), () {
                if (!mounted) return;
                setState(() => _attempt++);
              });
            });
          }
          return GestureDetector(
            onTap: isDownloading ? null : _retryDownload,
            child: Container(
              width: 220.w,
              height: 180.h,
              color: CustomColor.kUltraLightBg,
              alignment: Alignment.center,
              child: isDownloading
                  ? const CircularProgressIndicator(
                      color: CustomColor.kPrimaryColor,
                      strokeWidth: 2,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: CustomColor.kTextTertiary,
                          size: 28.r,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Tap to retry',
                          style: TextStyle(
                            color: CustomColor.kTextTertiary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _SaveImageButton extends StatelessWidget {
  final String mediaUrl;
  final String mediaId;
  final String roomId;

  const _SaveImageButton({
    required this.mediaUrl,
    required this.mediaId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final birdController = Get.find<BirdController>();
    return Obx(() {
      final isDownloading = birdController.downloadingMediaMap[mediaId] == true;
      return GestureDetector(
        onTap: () {
          if (isDownloading) {
            chatController.cancelDownload(mediaId);
          } else {
            chatController.downloadMedia(mediaUrl, mediaId, roomId, '1');
          }
        },
        child: Container(
          width: 28.r,
          height: 28.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CustomColor.kScrim45,
            borderRadius: BorderRadius.circular(AppRadius.md.r),
          ),
          child: isDownloading
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(
                    color: CustomColor.kTextOnDark,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.download_for_offline_rounded,
                  color: CustomColor.kTextOnDark,
                  size: 18,
                ),
        ),
      );
    });
  }
}
