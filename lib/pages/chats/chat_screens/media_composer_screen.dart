import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/composer_media_item.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/media_image_editor_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// WhatsApp-style multi-media composer.
///
/// Holds every staged media item (images / videos / documents), lets the user
/// swipe through a full-screen preview (pinch + double-tap zoom on images,
/// inline video playback), tweak quality (HD vs Standard), add captions per
/// item, drop/add items via the thumbnail strip, and send the whole batch
/// through the existing ChatController.sendComposerMedia pipeline.
class MediaComposerScreen extends StatefulWidget {
  const MediaComposerScreen({super.key});

  @override
  State<MediaComposerScreen> createState() => _MediaComposerScreenState();
}

class _MediaComposerScreenState extends State<MediaComposerScreen> {
  final ChatController _chat = Get.find<ChatController>();
  final PageController _pageController = PageController();
  final TextEditingController _captionCtrl = TextEditingController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  ComposerMediaItem? get _currentItem {
    final items = _chat.composerItems;
    if (items.isEmpty || _currentIndex >= items.length) return null;
    return items[_currentIndex];
  }

  void _syncCaptionToItem() {
    final item = _currentItem;
    if (item == null) {
      _captionCtrl.text = '';
      return;
    }
    if (_captionCtrl.text != item.caption) {
      _captionCtrl.text = item.caption;
    }
    _captionCtrl.selection =
        TextSelection.collapsed(offset: _captionCtrl.text.length);
  }

  Future<void> _confirmCancel() async {
    if (_chat.composerSending.value) {
      CustomSnackbar.show(
          title: 'Sending media',
          message: 'Please wait for the current send to finish.');
      return;
    }
    if (_chat.composerItems.isEmpty) {
      Get.back();
      return;
    }
    final discard = await Get.dialog<bool>(
      Dialog(
        backgroundColor: CustomColor.kDarkSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxxl.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46.w,
                height: 46.h,
                decoration: BoxDecoration(
                  color: CustomColor.kDangerRed.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: CustomColor.kDangerRed, size: 24),
              ),
              SizedBox(height: 14.h),
              Text(
                'Discard media?',
                style: TextStyle(
                  color: CustomColor.kTextOnDark,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Are you sure you want to discard the ${_chat.composerItems.length} selected item(s)?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CustomColor.kTextOnDarkSecondary,
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CustomColor.kTextOnDark,
                        side: const BorderSide(color: CustomColor.kDarkDivider),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('Keep editing'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Get.back(result: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: CustomColor.kDangerFill,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (discard == true) {
      _chat.clearComposer();
      Get.back();
    }
  }

  void _openAddSheet() {
    if (_chat.composerSending.value) return;
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Text(
                  'Add more media',
                  style: TextStyle(
                    color: CustomColor.kTextOnDark,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _addTile(
                icon: Icons.photo_library_outlined,
                color: CustomColor.kPrimaryColor,
                label: 'Photos',
                onTap: () {
                  Get.back();
                  _chat.addComposerPhotos();
                },
              ),
              _addTile(
                icon: Icons.videocam_outlined,
                color: CustomColor.kPrimaryMedium,
                label: 'Videos',
                onTap: () {
                  Get.back();
                  _chat.addComposerVideos();
                },
              ),
              _addTile(
                icon: Icons.photo_camera_outlined,
                color: CustomColor.kSuccess,
                label: 'Camera — Photo',
                onTap: () {
                  Get.back();
                  _chat.pickCameraComposer();
                },
              ),
              _addTile(
                icon: Icons.video_camera_front_outlined,
                color: CustomColor.kGoldAccent,
                label: 'Camera — Video',
                onTap: () {
                  Get.back();
                  _chat.pickCameraVideoComposer();
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
      backgroundColor: CustomColor.kDarkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _addTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: CustomColor.kTextOnDark,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    if (_chat.composerSending.value) return;
    if (_chat.composerItems.isEmpty) return;
    final anyPending = _chat.composerItems.any((e) => !e.failed);
    if (!anyPending) {
      CustomSnackbar.show(
          title: 'Nothing to send',
          message:
              'All selected media already failed. Remove them and try again.');
      return;
    }
    _chat.sendComposerMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.kDarkSecondaryColor,
      resizeToAvoidBottomInset: true,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _confirmCancel();
        },
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildPageArea()),
                _buildStrip(),
                _buildCaptionBar(),
              ],
            ),
            Positioned(left: -9999, top: 0, child: const _VideoThumbCapturer()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final int total = _chat.composerItems.length;
    final int index =
        total == 0 ? 0 : _currentIndex.clamp(0, total - 1).toInt();
    return Container(
      color: CustomColor.kDarkSurface2,
      padding: EdgeInsets.only(left: 6.w, right: 12.w, top: 4.h, bottom: 4.h),
      child: Row(
        children: [
          IconButton(
            onPressed: _confirmCancel,
            icon: const Icon(Icons.close_rounded,
                color: CustomColor.kTextOnDark, size: 26),
            tooltip: 'Close',
          ),
          Expanded(
            child: Center(
              child: Text(
                total == 0 ? 'Media' : 'Media $index/${total - 1}',
                style: TextStyle(
                  color: CustomColor.kTextOnDark,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _qualityChip(),
        ],
      ),
    );
  }

  Widget _qualityChip() {
    final bool hd = _chat.composerHdQuality.value;
    return GestureDetector(
      onTap: () {
        if (_chat.composerSending.value) return;
        _chat.composerHdQuality.toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: hd ? CustomColor.kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
          border: Border.all(
            color: hd ? CustomColor.kPrimaryColor : CustomColor.kDarkDivider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hd ? Icons.hd_rounded : Icons.hd_outlined,
              size: 16,
              color: hd
                  ? CustomColor.kTextOnDark
                  : CustomColor.kTextOnDarkSecondary,
            ),
            SizedBox(width: 4.w),
            Text(
              'HD',
              style: TextStyle(
                color: hd
                    ? CustomColor.kTextOnDark
                    : CustomColor.kTextOnDarkSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageArea() {
    return Obx(() {
      final items = List<ComposerMediaItem>.from(_chat.composerItems);
      if (items.isEmpty) {
        return const SizedBox.shrink();
      }
      if (_currentIndex >= items.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _currentIndex = items.length - 1);
          }
        });
        return const SizedBox.shrink();
      }
      return PageView.builder(
        controller: _pageController,
        itemCount: items.length,
        onPageChanged: (i) {
          setState(() => _currentIndex = i);
          _syncCaptionToItem();
        },
        itemBuilder: (context, i) {
          final item = items[i];
          return _ComposerMediaPage(
            key: PageStorageKey<String>(item.id),
            itemId: item.id,
          );
        },
        allowImplicitScrolling: true,
      );
    });
  }

  Widget _buildStrip() {
    return Obx(() {
      final items = List<ComposerMediaItem>.from(_chat.composerItems);
      final int safeIndex = _currentIndex.clamp(0, items.length - 1).toInt();
      return Container(
        color: CustomColor.kDarkSurface2,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: SizedBox(
          height: 68.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            children: [
              for (int i = 0; i < items.length; i++)
                ..._stripTile(items[i], i, i == safeIndex),
              _addMoreTile(),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _stripTile(ComposerMediaItem item, int index, bool active) {
    return [
      GestureDetector(
        onTap: () {
          _pageController.jumpToPage(index);
          setState(() => _currentIndex = index);
        },
        child: Container(
          width: 56.w,
          height: 56.w,
          margin: EdgeInsets.only(right: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            border: Border.all(
              color:
                  active ? CustomColor.kPrimaryColor : CustomColor.kDarkDivider,
              width: active ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _stripThumb(item),
                if (item.isVideo && !_chat.composerSending.value)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: CustomColor.kBlack.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: CustomColor.kTextOnDark, size: 14),
                    ),
                  ),
                if (item.isVideo)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1),
                      decoration: BoxDecoration(
                        color: CustomColor.kBlack.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppRadius.xs.r),
                      ),
                      child: Text(
                        item.videoDuration ?? '',
                        style: TextStyle(
                            color: CustomColor.kTextOnDark, fontSize: 9.sp),
                      ),
                    ),
                  ),
                if (!_chat.composerSending.value)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        _chat.removeComposerItem(item.id);
                        if (index < _currentIndex && _currentIndex > 0) {
                          setState(() => _currentIndex--);
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _pageController.hasClients) {
                            _pageController.jumpToPage(_currentIndex
                                .clamp(0, _chat.composerItems.length - 1)
                                .toInt());
                          }
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(2.r),
                        decoration: BoxDecoration(
                          color: CustomColor.kBlack.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: CustomColor.kTextOnDark, size: 13),
                      ),
                    ),
                  ),
                if (item.state == ComposerSendState.sending)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 3,
                      backgroundColor: CustomColor.kGlassColor,
                      valueColor: const AlwaysStoppedAnimation(
                          CustomColor.kPrimaryColor),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _stripThumb(ComposerMediaItem item) {
    if (item.isVideo && item.thumbnailPath != null) {
      return Image.file(File(item.thumbnailPath!), fit: BoxFit.cover);
    }
    if (item.isVideo) {
      return Container(
        color: CustomColor.kDarkSurface3,
        child: const Center(
          child: Icon(Icons.videocam_rounded,
              color: CustomColor.kTextOnDarkMuted, size: 22),
        ),
      );
    }
    if (item.isDocument) {
      return Container(
        color: CustomColor.kDarkSurface3,
        child: const Center(
          child: Icon(Icons.description_outlined,
              color: CustomColor.kTextOnDarkMuted, size: 20),
        ),
      );
    }
    return Image.file(
      File(item.file.path),
      fit: BoxFit.cover,
      cacheWidth: 240,
      errorBuilder: (_, __, ___) => Container(
        color: CustomColor.kDarkSurface3,
        child: const Icon(Icons.broken_image_outlined,
            color: CustomColor.kTextOnDarkMuted),
      ),
    );
  }

  Widget _addMoreTile() {
    return GestureDetector(
      onTap: _openAddSheet,
      child: Container(
        width: 56.w,
        height: 56.w,
        decoration: BoxDecoration(
          color: CustomColor.kDarkSurface3,
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          border: Border.all(color: CustomColor.kDarkDivider),
        ),
        child: const Icon(Icons.add_rounded,
            color: CustomColor.kPrimaryMedium, size: 26),
      ),
    );
  }

  Widget _buildCaptionBar() {
    return Container(
      color: CustomColor.kDarkSurface2,
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 8.h),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _captionCtrl,
                enabled: !_chat.composerSending.value,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(
                    color: CustomColor.kTextOnDark, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Add a caption…',
                  hintStyle: TextStyle(
                      color: CustomColor.kTextOnDarkMuted, fontSize: 15),
                  filled: true,
                  fillColor: CustomColor.kDarkInputFill,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                    borderSide:
                        const BorderSide(color: CustomColor.kDarkDivider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                    borderSide:
                        const BorderSide(color: CustomColor.kPrimaryColor),
                  ),
                ),
                onChanged: (value) {
                  final item = _currentItem;
                  if (item != null) item.caption = value;
                },
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (mounted && _pageController.hasClients) {
                      _pageController.jumpToPage(_currentIndex
                          .clamp(0, _chat.composerItems.length - 1)
                          .toInt());
                    }
                  });
                },
              ),
            ),
            SizedBox(width: 10.w),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Obx(() {
      final bool sending = _chat.composerSending.value;
      return GestureDetector(
        onTap: sending ? null : _send,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 54.w,
          height: 54.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: CustomColor.primaryGradient,
            boxShadow: sending
                ? null
                : [
                    BoxShadow(
                      color: CustomColor.kPrimaryGlow,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: CustomColor.kTextOnDark,
                    ),
                  )
                : const Icon(Icons.arrow_upward_rounded,
                    color: CustomColor.kTextOnDark, size: 26),
          ),
        ),
      );
    });
  }
}

/// A single preview page in the composer (image / video / document).
class _ComposerMediaPage extends StatefulWidget {
  const _ComposerMediaPage({super.key, required this.itemId});

  final String itemId;

  @override
  State<_ComposerMediaPage> createState() => _ComposerMediaPageState();
}

class _ComposerMediaPageState extends State<_ComposerMediaPage> {
  final ChatController _chat = Get.find<ChatController>();

  ComposerMediaItem? get _item {
    for (final e in _chat.composerItems) {
      if (e.id == widget.itemId) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (item == null) {
      return const SizedBox.shrink();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.isImage)
          _buildImagePage(item)
        else if (item.isVideo)
          _ComposerVideoView(item: item)
        else
          _buildDocumentPage(item),
        _pageOverlay(item),
      ],
    );
  }

  Widget _buildImagePage(ComposerMediaItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: CustomColor.kDarkSecondaryColor),
        _ZoomableImage(filePath: item.file.path),
        Positioned(
          top: 8,
          right: 10,
          child: IconButton(
            onPressed: () async {
              if (_chat.composerSending.value) return;
              final File? edited = await Get.to<File?>(
                () => MediaImageEditorScreen(item: item),
              );
              if (edited != null && mounted) {
                item.file = edited;
                _chat.composerItems.refresh();
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: CustomColor.kScrim45,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
              ),
            ),
            icon: const Icon(Icons.edit_rounded,
                color: CustomColor.kTextOnDark, size: 20),
            tooltip: 'Edit',
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentPage(ComposerMediaItem item) {
    String? sizeLabel;
    int sizeBytes = 0;
    try {
      sizeBytes = item.file.lengthSync();
    } catch (_) {}
    sizeLabel = _fileSize(sizeBytes);
    final ext = item.file.path.split('.').last.toUpperCase();
    final (:icon, :color) = _docStyle(ext);
    return Container(
      color: CustomColor.kDarkSecondaryColor,
      padding: EdgeInsets.all(28.w),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _fileCard(ext, icon, color),
            SizedBox(height: 16.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                item.file.path.split('/').last,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: CustomColor.kTextOnDark,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              '${ext.toLowerCase()} · $sizeLabel',
              style: TextStyle(
                  color: CustomColor.kTextOnDarkMuted, fontSize: 12.sp),
            ),
            SizedBox(height: 14.h),
            Text(
              'This will be sent (and saved) as a File attachment.',
              style: TextStyle(
                  color: CustomColor.kTextOnDarkMuted, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileCard(String ext, IconData icon, Color color) {
    return Container(
      width: 96.w,
      height: 110.h,
      decoration: BoxDecoration(
        gradient: CustomColor.glassGradient,
        borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
        border: Border.all(color: CustomColor.kDarkBorder),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kBlack.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color, size: 54),
          Positioned(
            bottom: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.sm.r),
              ),
              child: Text(
                ext,
                style: TextStyle(
                  color: color,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageOverlay(ComposerMediaItem item) {
    if (item.state == ComposerSendState.sending) {
      return Container(
        color: CustomColor.kBlack.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                value: item.progress,
                strokeWidth: 3,
                color: CustomColor.kPrimaryColor,
                backgroundColor: CustomColor.kOverlay24,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Uploading ${(item.progress * 100).round()}%',
              style: TextStyle(
                color: CustomColor.kTextOnDark,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    if (item.failed) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          color: CustomColor.kDarkSurface.withValues(alpha: 0.55),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: CustomColor.kDangerRed, size: 18),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Could not send. Tap send again to retry.',
                  style: TextStyle(
                      color: CustomColor.kTextOnDarkSecondary, fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Pinch / double-tap zoomable image used on the composer preview pages.
class _ZoomableImage extends StatefulWidget {
  const _ZoomableImage({required this.filePath});

  final String filePath;

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        final v = _anim?.value;
        if (v != null) _transform.value = v;
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final double currentScale = _transform.value.getMaxScaleOnAxis();
    if (currentScale > 1.05) {
      _anim = Matrix4Tween(
        begin: _transform.value,
        end: Matrix4.identity(),
      ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    } else {
      const double zoom = 2.6;
      final Offset position = details.localPosition;
      final double tx = position.dx * (1 - zoom);
      final double ty = position.dy * (1 - zoom);
      final Matrix4 target = Matrix4(
        zoom,
        0,
        0,
        0,
        0,
        zoom,
        0,
        0,
        0,
        0,
        1,
        0,
        tx,
        ty,
        0,
        1,
      );
      _anim = Matrix4Tween(
        begin: _transform.value,
        end: target,
      ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    }
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      child: InteractiveViewer(
        transformationController: _transform,
        maxScale: 5,
        minScale: 1,
        clipBehavior: Clip.none,
        panEnabled: true,
        child: Center(
          child: Image.file(
            File(widget.filePath),
            fit: BoxFit.contain,
            cacheWidth: 1600,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: CustomColor.kTextOnDarkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline video playback page for a composer video slot, with play/pause,
/// scrubbing, mute and elapsed/total time. Meta info (duration + first-frame
/// thumbnail) is filled in by the [_VideoThumbCapturer].
class _ComposerVideoView extends StatefulWidget {
  const _ComposerVideoView({required this.item});

  final ComposerMediaItem item;

  @override
  State<_ComposerVideoView> createState() => _ComposerVideoViewState();
}

class _ComposerVideoViewState extends State<_ComposerVideoView> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _playing = false;
  bool _muted = false;
  String _elapsed = '0:00';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.file(widget.item.file);
      _controller = c;
      await c.initialize();
      if (!mounted) {
        try {
          c.dispose();
        } catch (_) {}
        return;
      }
      c.addListener(_onTick);
      setState(() {
        _ready = true;
        _elapsed = _fmtDuration(c.value.position);
      });
    } catch (e) {
      debugPrint('composer video init error: $e');
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      _playing = c.value.isPlaying;
      _elapsed = _fmtDuration(c.value.position);
    });
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_ready) return;
    c.value.isPlaying ? c.pause() : c.play();
  }

  String _fmtDuration(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes % 60;
    final int s = d.inSeconds % 60;
    final String mm = m.toString().padLeft(2, '0');
    final String ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    try {
      _controller?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Container(
      color: CustomColor.kDarkSecondaryColor,
      child: Center(
        child: _ready && c != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(child: VideoPlayer(c)),
                  if (!_playing)
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: CustomColor.kTextOnDark, size: 40),
                      ),
                    ),
                  Positioned(
                    left: 12.w,
                    right: 12.w,
                    bottom: 14.h,
                    child: _videoControls(c),
                  ),
                ],
              )
            : const CircularProgressIndicator.adaptive(),
      ),
    );
  }

  Widget _videoControls(VideoPlayerController c) {
    return GestureDetector(
      onTap: () {}, // absorb taps so the slider isn't treated as page swipe
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 8.h),
        decoration: BoxDecoration(
          color: CustomColor.kScrim60,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: CustomColor.kPrimaryColor,
                bufferedColor: CustomColor.kOverlay38,
                backgroundColor: CustomColor.kOverlay24,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Text(
                  _elapsed,
                  style: TextStyle(
                      color: CustomColor.kTextOnDark, fontSize: 11.sp),
                ),
                Spacer(),
                Text(
                  _fmtDuration(c.value.duration),
                  style: TextStyle(
                      color: CustomColor.kTextOnDarkSecondary, fontSize: 11.sp),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    setState(() => _muted = !_muted);
                    c.setVolume(_muted ? 0 : 1);
                  },
                  child: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: CustomColor.kTextOnDark,
                    size: 20,
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

/// Sequentially captures first-frame thumbnails + durations for staged video
/// items, so the strip shows real previews without the user opening the page.
/// Renders off-screen; each capture reuses the existing video_player pipe.
class _VideoThumbCapturer extends StatefulWidget {
  const _VideoThumbCapturer();

  @override
  State<_VideoThumbCapturer> createState() => _VideoThumbCapturerState();
}

class _VideoThumbCapturerState extends State<_VideoThumbCapturer> {
  final ChatController _chat = Get.find<ChatController>();
  VideoPlayerController? _controller;
  GlobalKey? _boundaryKey;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pump());
  }

  ComposerMediaItem? _nextPending() {
    for (final e in _chat.composerItems) {
      if (e.isVideo && e.thumbnailPath == null) return e;
    }
    return null;
  }

  Future<void> _pump() async {
    if (_working) return;
    final item = _nextPending();
    if (item == null) return;
    _working = true;
    final VideoPlayerController c = VideoPlayerController.file(item.file);
    _controller = c;
    _boundaryKey = GlobalKey();
    setState(() {});
    try {
      await c.initialize();
      await c.setLooping(false);
      await c.setVolume(0);
      if (!mounted) {
        try {
          c.dispose();
        } catch (_) {}
        return;
      }
      setState(() {});
      await c.seekTo(Duration.zero);
      await c.play();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) await WidgetsBinding.instance.endOfFrame;
      final RenderRepaintBoundary? boundary = _boundaryKey?.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null && mounted) {
        final ui.Image img = await boundary.toImage(pixelRatio: 0.8);
        final ByteData? bytes =
            await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final File thumb =
              File('${dir.path}/hb_thumb_${item.id}_$millisStamp.png');
          await thumb.writeAsBytes(bytes.buffer.asUint8List());
          if (item.thumbnailPath == null) {
            item.thumbnailPath = thumb.path;
            item.videoDuration = _fmtDuration(c.value.duration);
            _chat.composerItems.refresh();
          }
        }
      }
    } catch (e) {
      debugPrint('composer thumb capture: $e');
    } finally {
      try {
        c.dispose();
      } catch (_) {}
      _controller = null;
      _boundaryKey = null;
      if (mounted) {
        setState(() {});
        _working = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _pump());
      }
    }
  }

  static String get millisStamp =>
      DateTime.now().microsecondsSinceEpoch.toString();

  static String _fmtDuration(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes % 60;
    final int s = d.inSeconds % 60;
    final String mm = m.toString().padLeft(2, '0');
    final String ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return SizedBox(
      width: 360,
      height: 240,
      child: c == null
          ? const SizedBox.shrink()
          : RepaintBoundary(
              key: _boundaryKey,
              child: VideoPlayer(c),
            ),
    );
  }
}

String _fileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024).toStringAsFixed(0)} KB';
}

({IconData icon, Color color}) _docStyle(String ext) {
  switch (ext.toLowerCase()) {
    case 'pdf':
      return (
        icon: Icons.picture_as_pdf_rounded,
        color: CustomColor.kDangerRed
      );
    case 'doc':
    case 'docx':
      return (
        icon: Icons.description_rounded,
        color: CustomColor.kPrimaryColor
      );
    case 'xls':
    case 'xlsx':
      return (
        icon: Icons.table_chart_outlined,
        color: CustomColor.kSuccess,
      );
    case 'ppt':
    case 'pptx':
      return (
        icon: Icons.slideshow_outlined,
        color: CustomColor.kGoldAccent,
      );
    case 'zip':
    case 'rar':
    case 'tar':
    case 'gz':
      return (
        icon: Icons.folder_zip_rounded,
        color: CustomColor.kInfo,
      );
    default:
      return (
        icon: Icons.insert_drive_file_rounded,
        color: CustomColor.kTextOnDarkSecondary,
      );
  }
}
