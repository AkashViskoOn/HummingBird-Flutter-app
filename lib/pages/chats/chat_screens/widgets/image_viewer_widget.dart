import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/chat_ui/message_action_sheet.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// WhatsApp-style fullscreen image viewer with pinch / double-tap zoom,
/// swipe-down-to-dismiss, auto-retry and a WhatsApp-style action sheet
/// (reply, share, forward, star, react, delete, info).
class FullScreenImageView extends StatefulWidget {
  final String url;
  final Uint8List? bytes;
  final String? heroTag;
  final ImageProvider? imageProvider;
  final String? messageId;

  const FullScreenImageView({
    super.key,
    required this.url,
    this.bytes,
    this.heroTag,
    this.imageProvider,
    this.messageId,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  final TransformationController _transformation = TransformationController();
  bool _zoomed = false;
  bool _showChrome = true;
  double _dismissOffset = 0;
  bool _failed = false;
  bool _sharing = false;
  int _retryToken = 0;

  Messages? _message;
  bool _isGroup = false;

  @override
  void initState() {
    super.initState();
    _loadMessage();
  }

  void _loadMessage() {
    final messageId = widget.messageId;
    if (messageId == null || messageId.isEmpty) return;
    final message = LocalDatabase.getSingleMessages(messageId);
    _message = message;
    if (message?.mRoomId != null) {
      final roomId = message!.mRoomId!;
      final room = LocalDatabase.getRooms().where((r) => r.rId == roomId);
      if (room.isNotEmpty) {
        _isGroup = room.first.rType == '1';
      }
    }
  }

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_zoomed) {
      _transformation.value = Matrix4.identity();
      _zoomed = false;
    } else {
      _transformation.value = Matrix4.identity()..scaleByDouble(2.5, 2.5, 1, 1);
      _zoomed = true;
    }
    setState(() {});
  }

  void _retry() {
    setState(() {
      _failed = false;
      _zoomed = false;
      _retryToken++;
      _transformation.value = Matrix4.identity();
    });
  }

  void _autoRetry() {
    if (_retryToken > 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted || _failed == false) return;
        _retry();
      });
    });
  }

  Widget _image() {
    final ImageProvider? provider = widget.imageProvider ??
        (widget.bytes != null ? MemoryImage(widget.bytes!) : null);

    return KeyedSubtree(
      key: ValueKey('image_retry_$_retryToken'),
      child: provider != null
          ? Image(
              image: provider,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _buildError(),
            )
          : CachedNetworkImage(
              imageUrl: AppHelper.resolveMediaUrl(widget.url),
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, __) => _buildLoading(null),
              errorWidget: (_, __, ___) {
                _autoRetry();
                return _buildError();
              },
            ),
    );
  }

  Widget _buildLoading(ImageChunkEvent? progress) {
    final value = progress != null && progress.expectedTotalBytes != null
        ? (progress.cumulativeBytesLoaded / progress.expectedTotalBytes!)
            .clamp(0.0, 1.0)
        : null;
    return Center(
      child: SizedBox(
        width: 40.r,
        height: 40.r,
        child: CircularProgressIndicator(
          color: CustomColor.kPrimaryColor,
          strokeWidth: 3,
          value: value,
        ),
      ),
    );
  }

  Widget _buildError() {
    if (!_failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _failed = true);
      });
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined,
              size: 56, color: CustomColor.kOverlay38),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _retry,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.rounded.r),
              ),
              child: Text('Retry',
                  style: TextStyle(
                      color: CustomColor.kTextOnDark, fontSize: 14.sp)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      Uint8List? bytes = widget.bytes;
      if (bytes == null && widget.messageId != null) {
        final chatController = Get.find<ChatController>();
        bytes = await chatController.getMediaFromPath(widget.messageId!);
      }
      bytes ??= await ApiService().downloadMedia(
        url: AppHelper.resolveMediaUrl(widget.url),
        mediaId: widget.messageId ?? 'viewer',
      );
      if (bytes == null) {
        CustomSnackbar.error(
            title: 'Error', message: 'Could not download image');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/humming-viewer-${widget.messageId ?? DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
    } catch (_) {
      CustomSnackbar.error(title: 'Error', message: 'Could not share image');
    } finally {
      if (mounted) setState(() => _sharing = false);
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

  String get _headerTitle {
    final message = _message;
    if (message == null) return '';
    final time = AppHelper.formatSentTime(message);
    return time.isNotEmpty ? time : (message.mStatus ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (_zoomed) return;
          setState(() => _dismissOffset += details.delta.dy);
        },
        onVerticalDragEnd: (details) {
          if (_zoomed) {
            setState(() => _dismissOffset = 0);
            return;
          }
          if (_dismissOffset.abs() > 160 ||
              details.primaryVelocity != null &&
                  details.primaryVelocity!.abs() > 1200) {
            Get.back();
          } else {
            setState(() => _dismissOffset = 0);
          }
        },
        child: Container(
          color: Colors.black.withValues(
            alpha: 1 - (_dismissOffset.abs() / 500).clamp(0.0, 0.6),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, _dismissOffset),
                child: GestureDetector(
                  onTap: () => setState(() => _showChrome = !_showChrome),
                  onDoubleTap: _toggleZoom,
                  child: InteractiveViewer(
                    transformationController: _transformation,
                    clipBehavior: Clip.none,
                    minScale: 1,
                    maxScale: 5,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(200),
                    onInteractionUpdate: (details) {
                      final scale = details.scale;
                      if ((scale < 1.05 && _showChrome == false) ||
                          (scale > 1.05 && _showChrome == true)) {
                        setState(() => _showChrome = scale <= 1.05);
                      }
                    },
                    child: SizedBox.expand(child: _image()),
                  ),
                ),
              ),
              if (_showChrome && !_zoomed) ...[
                _buildTopBar(),
                _buildCaptionArea(),
                _buildBottomActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8.h,
      left: 0.w,
      right: 0.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(AppSpacing.md.r),
                decoration: BoxDecoration(
                  color: CustomColor.kScrim20,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: AppIcons.xxl, color: CustomColor.kTextOnDark),
              ),
            ),
            SizedBox(width: AppSpacing.lg.w),
            if (_headerTitle.isNotEmpty)
              Text(
                _headerTitle,
                style: AppTextStyles.titleSm
                    .copyWith(color: CustomColor.kTextOnDark),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionArea() {
    final caption = _message?.mMessage;
    if (caption == null || caption.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: AppSpacing.xl.w,
      right: AppSpacing.xl.w,
      bottom: 96.h,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg.w,
            vertical: AppSpacing.sm.h,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppSpacing.md.r),
          ),
          child: Text(
            caption,
            style:
                AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextOnDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final message = _message;
    return Positioned(
      left: 0.w,
      right: 0.w,
      bottom: 0.h,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: () {
                if (message != null) {
                  Get.find<ChatController>().replyToMessage(message);
                  Get.back();
                }
              },
            ),
            _actionButton(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: _share,
              loading: _sharing,
            ),
            _actionButton(
              icon: Icons.more_vert_rounded,
              label: 'More',
              onTap: _showActions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: loading
                  ? Padding(
                      padding: EdgeInsets.all(12.r),
                      child: const CircularProgressIndicator(
                        color: CustomColor.kTextOnDark,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(icon, color: CustomColor.kTextOnDark, size: 22.r),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTextStyles.labelSm
                  .copyWith(color: CustomColor.kTextOnDark),
            ),
          ],
        ),
      ),
    );
  }
}
