import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';

class MiniCallOverlay {
  MiniCallOverlay._();

  static OverlayEntry? _entry;
  static bool get isShowing => _entry != null;

  // Find a usable Overlay without crashing. Falls back to GetX's root overlay
  // context, which is valid whenever a GetMaterialApp is active.
  static OverlayState? _findOverlay(BuildContext? context) {
    try {
      if (context != null && context.mounted) {
        return Overlay.of(context, rootOverlay: true);
      }
    } catch (_) {}
    try {
      final oc = Get.overlayContext;
      if (oc != null) return Overlay.of(oc, rootOverlay: true);
    } catch (_) {}
    return null;
  }

  static void show(BuildContext? context) {
    if (_entry != null) return;

    final controller = Get.find<CallController>();
    final overlay = _findOverlay(context);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (_) => _MiniCallWidget(controller: controller),
    );

    overlay.insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _MiniCallWidget extends StatefulWidget {
  final CallController controller;
  const _MiniCallWidget({required this.controller});

  // Voice card size (logical px, stable across screens).
  static const double voiceWidth = 212;
  static const double voiceHeight = 80;

  // Video PiP bounds (logical px). Users can pinch between these.
  static const double videoMinW = 130;
  static const double videoMinH = 190;
  static const double videoMaxW = 340;
  static const double videoMaxH = 480;

  @override
  State<_MiniCallWidget> createState() => _MiniCallWidgetState();
}

class _MiniCallWidgetState extends State<_MiniCallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  Offset _position = Offset.zero;
  Size _videoSize = const Size(200, 290);
  Size _startVideoSize = const Size(200, 290);
  bool _initialized = false;
  Offset _lastFocus = Offset.zero;

  bool get _isVideo => widget.controller.callType.value == 'video';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Size _viewSize() => MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first)
      .size;

  double _viewTopPadding() => MediaQueryData.fromView(
          WidgetsBinding.instance.platformDispatcher.views.first)
      .padding
      .top;

  void _initPosition() {
    if (_initialized) return;
    _initialized = true;
    final size = _viewSize();
    if (_isVideo) {
      // Top-right, just below the status bar.
      _position = Offset(
        (size.width - _videoSize.width - 12).clamp(0.0, size.width),
        _viewTopPadding() + 8,
      );
    } else {
      _position = Offset(
        size.width - _MiniCallWidget.voiceWidth - 16,
        size.height * 0.35,
      );
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startVideoSize = _videoSize;
    _lastFocus = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final dx = details.focalPoint.dx - _lastFocus.dx;
    final dy = details.focalPoint.dy - _lastFocus.dy;
    _lastFocus = details.focalPoint;

    setState(() {
      _position += Offset(dx, dy);
      if (_isVideo && details.pointerCount >= 2) {
        double newW = (_startVideoSize.width * details.scale)
            .clamp(_MiniCallWidget.videoMinW, _MiniCallWidget.videoMaxW);
        double newH = (_startVideoSize.height * details.scale)
            .clamp(_MiniCallWidget.videoMinH, _MiniCallWidget.videoMaxH);
        _videoSize = Size(newW, newH);
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    final size = _viewSize();
    final w = _isVideo ? _videoSize.width : _MiniCallWidget.voiceWidth;
    final h = _isVideo ? _videoSize.height : _MiniCallWidget.voiceHeight;
    double x = _position.dx.clamp(0.0, size.width - w);
    double y = _position.dy.clamp(
      _viewTopPadding(),
      size.height - h - 20,
    );
    setState(() {
      _position = Offset(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    _initPosition();

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              onScaleEnd: _onScaleEnd,
              child: _buildCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Obx(() {
      final c = widget.controller;
      if (_isVideo) {
        return _buildVideoCard(c);
      }
      return _buildVoiceCard(c);
    });
  }

  // ---- Video call: PiP showing the remote video feed, resizable ----
  Widget _buildVideoCard(CallController c) {
    final duration = c.formattedDuration;
    final state = c.callState.value;
    final hasRemote = c.remoteRenderer.srcObject != null;

    return Container(
      width: _videoSize.width,
      height: _videoSize.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CustomColor.kWhite.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kScrim60,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.20),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasRemote)
            RTCVideoView(
              c.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            _avatarFill(c),
          // Soft gradient at the bottom so labels stay readable.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    CustomColor.kScrim60,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Top-right controls
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _videoCircleButton(
                  icon: Icons.fullscreen_rounded,
                  onTap: () {
                    MiniCallOverlay.dismiss();
                    c.showActiveCallScreen();
                  },
                ),
                SizedBox(width: 8),
                _videoCircleButton(
                  icon: Icons.call_end_rounded,
                  red: true,
                  onTap: () {
                    MiniCallOverlay.dismiss();
                    c.endCall();
                  },
                ),
              ],
            ),
          ),
          // Bottom-left: name + duration
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.otherUserName.value,
                  style: GoogleFonts.poppins(
                    color: CustomColor.kTextOnDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6)
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.videocam_rounded,
                      color: state == 'connected'
                          ? CustomColor.kOnlineGreen
                          : CustomColor.kTextOnDarkSecondary,
                      size: 11,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        state == 'connected'
                            ? duration
                            : (state == 'reconnecting'
                                ? 'Reconnecting...'
                                : (state == 'connecting'
                                    ? 'Connecting...'
                                    : (c.iAmCaller
                                        ? 'Calling...'
                                        : 'Ringing...'))),
                        style: GoogleFonts.poppins(
                          color: state == 'connected'
                              ? CustomColor.kOnlineGreen
                              : CustomColor.kTextOnDarkSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 4)
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool red = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: red ? CustomColor.kDangerRed : CustomColor.kScrim40,
          shape: BoxShape.circle,
          border: Border.all(
            color: CustomColor.kWhite.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(icon, color: CustomColor.kTextOnDark, size: 17),
      ),
    );
  }

  Widget _avatarFill(CallController c) {
    final image = _getContactImage(c.otherUserId.value);
    return Container(
      color: CustomColor.kDarkSurface3,
      alignment: Alignment.center,
      child: ClipOval(
        child: SizedBox(
          width: 72,
          height: 72,
          child: image != null
              ? CachedNetworkImage(
                  imageUrl: image,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Image.asset(
                      AppAssets.defaultProfilePic,
                      fit: BoxFit.cover),
                )
              : Image.asset(AppAssets.defaultProfilePic, fit: BoxFit.cover),
        ),
      ),
    );
  }

  // ---- Voice call: compact glass card with avatar + labels ----
  Widget _buildVoiceCard(CallController c) {
    final duration = c.formattedDuration;
    final state = c.callState.value;
    final statusText = state == 'connected'
        ? duration
        : (state == 'reconnecting'
            ? 'Reconnecting...'
            : (state == 'connecting'
                ? 'Connecting...'
                : (c.iAmCaller ? 'Calling...' : 'Ringing...')));

    return Container(
      width: _MiniCallWidget.voiceWidth,
      height: _MiniCallWidget.voiceHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CustomColor.kDarkSurface3, CustomColor.kDarkSurface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CustomColor.kWhite.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(c),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.otherUserName.value,
                    style: GoogleFonts.poppins(
                      color: CustomColor.kTextOnDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.call_rounded,
                        color: state == 'connected'
                            ? CustomColor.kOnlineGreen
                            : (state == 'reconnecting'
                                ? CustomColor.kWarning
                                : CustomColor.kTextOnDarkSecondary),
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            color: state == 'connected'
                                ? CustomColor.kOnlineGreen
                                : (state == 'reconnecting'
                                    ? CustomColor.kWarning
                                    : CustomColor.kTextOnDarkSecondary),
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildVoiceExpandButton(c),
          _buildVoiceEndButton(c),
        ],
      ),
    );
  }

  Widget _buildAvatar(CallController c) {
    final image = _getContactImage(c.otherUserId.value);
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              CustomColor.kPrimaryColor,
              CustomColor.kPrimaryMedium,
            ],
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: CustomColor.kDarkSurface3,
          backgroundImage: image != null
              ? CachedNetworkImageProvider(image)
              : const AssetImage(AppAssets.defaultProfilePic) as ImageProvider,
          onBackgroundImageError: (_, __) {},
        ),
      ),
    );
  }

  Widget _buildVoiceExpandButton(CallController c) {
    return GestureDetector(
      onTap: () {
        MiniCallOverlay.dismiss();
        c.showActiveCallScreen();
      },
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: CustomColor.kWhite.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: CustomColor.kWhite.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.fullscreen_rounded,
          color: CustomColor.kTextOnDark,
          size: 15,
        ),
      ),
    );
  }

  Widget _buildVoiceEndButton(CallController c) {
    return GestureDetector(
      onTap: () {
        MiniCallOverlay.dismiss();
        c.endCall();
      },
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 8, top: 18, bottom: 18),
        decoration: const BoxDecoration(
          color: CustomColor.kDangerRed,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.call_end_rounded,
          color: CustomColor.kTextOnDark,
          size: 15,
        ),
      ),
    );
  }

  String? _getContactImage(String userId) {
    final user = LocalDatabase.getUser(userId);
    if (user?.userImage?.isNotEmpty == true) {
      return '${Endpoints.mediaBaseUrl}${user!.userImage}';
    }
    return null;
  }
}
