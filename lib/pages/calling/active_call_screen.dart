import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM DARK CALL UI
//
// This file ONLY restyles the UI. All call logic (WebRTC, routing, states,
// renderers, sockets, timers) lives in the controller and is untouched — every
// button here calls the existing controller methods.
// ═══════════════════════════════════════════════════════════════════════════

class ActiveCallScreen extends StatelessWidget {
  final bool isCaller;
  const ActiveCallScreen({super.key, required this.isCaller});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (controller.callState.value == 'connected' ||
            controller.callState.value == 'ringing' ||
            controller.callState.value == 'connecting' ||
            controller.callState.value == 'reconnecting') {
          controller.showMiniCallOverlay();
          controller.markCallScreenClosed();
          Navigator.of(context).pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: CustomColor.kDarkBackground,
          body: SafeArea(
            top: false,
            bottom: false,
            child: Obx(() {
              if (controller.callType.value == 'video') {
                return _VideoCallBody(controller: controller);
              }
              return _VoiceCallBody(controller: controller);
            }),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// VOICE CALL
// ══════════════════════════════════════════════════════════════════════════

class _VoiceCallBody extends StatefulWidget {
  final CallController controller;
  const _VoiceCallBody({required this.controller});

  @override
  State<_VoiceCallBody> createState() => _VoiceCallBodyState();
}

class _VoiceCallBodyState extends State<_VoiceCallBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    CallController.setOverlayContext(context);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CustomColor.kDarkDeep,
            CustomColor.kDarkBackground,
            CustomColor.kDarkDeep,
          ],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topPadding),
          _buildTopBar(controller),
          const Spacer(flex: 2),
          _buildAvatarSection(controller),
          SizedBox(height: 32.h),
          _buildNameAndStatus(controller),
          const Spacer(flex: 3),
          _buildControlPanel(controller, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildTopBar(CallController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          _GlassIconButton(
            semanticLabel: 'Minimise call',
            icon: Icons.keyboard_arrow_down_rounded,
            onTap: () {
              if (controller.callState.value == 'connected' ||
                  controller.callState.value == 'ringing' ||
                  controller.callState.value == 'connecting' ||
                  controller.callState.value == 'reconnecting') {
                controller.showMiniCallOverlay();
                controller.markCallScreenClosed();
                Get.back();
              }
            },
          ),
          const Spacer(),
          _GlassSmallButton(
            icon: Icons.person_add_rounded,
            onTap: () {
              CustomSnackbar.show(
                  title: 'Coming Soon',
                  message: 'Add participant will be available soon');
            },
          ),
          SizedBox(width: 12.w),
          _GlassSmallButton(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () {
              CustomSnackbar.show(
                  title: 'Coming Soon',
                  message: 'In-call chat will be available soon');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(CallController controller) {
    return Obx(() {
      final isRingingOrConnecting = controller.callState.value == 'ringing' ||
          controller.callState.value == 'connecting';

      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulseValue = isRingingOrConnecting
              ? 1.0 + 0.03 * math.sin(_pulseController.value * math.pi * 2)
              : 1.0;
          final glowOpacity = isRingingOrConnecting
              ? 0.30 + 0.10 * math.sin(_pulseController.value * math.pi * 2)
              : 0.18;

          return Transform.scale(
            scale: pulseValue,
            child: SizedBox(
              width: 150.r,
              height: 150.r,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150.r,
                    height: 150.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CustomColor.kPrimaryColor
                              .withValues(alpha: glowOpacity),
                          blurRadius: 46,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: CustomColor.kPrimaryMedium
                              .withValues(alpha: glowOpacity * 0.5),
                          blurRadius: 70,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 140.r,
                    height: 140.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          CustomColor.kPrimaryColor,
                          CustomColor.kPrimaryMedium,
                        ],
                      ),
                      border: Border.all(
                        color: CustomColor.kWhite.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                    ),
                    padding: EdgeInsets.all(3.r),
                    child: _ContactAvatar(
                      userId: controller.otherUserId.value,
                      radius: 67.r,
                    ),
                  ),
                  if (isRingingOrConnecting)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PulseRingPainter(
                          animation: _pulseController.value,
                          color: CustomColor.kPrimaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildNameAndStatus(CallController controller) {
    return Column(
      children: [
        Obx(() => Text(
              controller.otherUserName.value,
              style: AppTextStyles.displayLarge
                  .copyWith(color: CustomColor.kTextOnDark),
              textAlign: TextAlign.center,
            )),
        SizedBox(height: 10.h),
        Obx(() {
          final state = controller.callState.value;
          if (state == 'connecting') {
            return const _ConnectingDots();
          }
          return Text(
            _statusLabel(controller),
            style: AppTextStyles.bodyLg
                .copyWith(color: CustomColor.kTextOnDarkSecondary),
          );
        }),
        SizedBox(height: 12.h),
        const _SecureCallIndicator(),
      ],
    );
  }

  Widget _buildControlPanel(CallController controller, double bottomPadding) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h + bottomPadding),
      child: _GlassDock(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Obx(() => _CallButton(
                  icon: _getAudioRouteIcon(controller.currentAudioRoute.value),
                  label:
                      _getAudioRouteLabel(controller.currentAudioRoute.value),
                  isActive:
                      controller.currentAudioRoute.value == AudioRoute.speaker,
                  onTap: () => _onAudioButtonTap(controller),
                  onLongPress: () => controller.toggleSpeaker(),
                )),
            Obx(() => _CallButton(
                  icon: controller.isMicMuted.value
                      ? Icons.mic_off_rounded
                      : Icons.mic_rounded,
                  label: 'Mute',
                  isActive: controller.isMicMuted.value,
                  onTap: controller.toggleMute,
                )),
            _CallButton(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              onTap: () => _showMoreMenu(controller),
            ),
            _EndCallButton(onTap: controller.endCall),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// VIDEO CALL
// ══════════════════════════════════════════════════════════════════════════

class _VideoCallBody extends StatefulWidget {
  final CallController controller;
  const _VideoCallBody({required this.controller});

  @override
  State<_VideoCallBody> createState() => _VideoCallBodyState();
}

class _VideoCallBodyState extends State<_VideoCallBody> {
  Offset _localVideoPosition = Offset.zero;
  bool _positioned = false;
  // WhatsApp-style: tapping the small preview swaps which feed is full screen.
  bool _previewSwapped = false;

  @override
  void initState() {
    super.initState();
    CallController.setOverlayContext(context);
    final c = widget.controller;
    c.localRenderer.addListener(_onRendererChanged);
    c.remoteRenderer.addListener(_onRendererChanged);
  }

  @override
  void dispose() {
    final c = widget.controller;
    c.localRenderer.removeListener(_onRendererChanged);
    c.remoteRenderer.removeListener(_onRendererChanged);
    super.dispose();
  }

  void _onRendererChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final topPadding = MediaQuery.of(context).padding.top;

    if (!_positioned) {
      final size = MediaQuery.of(context).size;
      _localVideoPosition = Offset(
        size.width - 116.w - 16.w,
        topPadding + 70.h,
      );
      _positioned = true;
    }

    final isCameraOff = c.isCameraOff.value;
    final callState = c.callState.value;
    final isConnected = callState == 'connected';
    final hasLocalStream = c.localRenderer.srcObject != null;
    final hasRemoteStream = c.remoteRenderer.srcObject != null;
    final showLocalCamera = hasLocalStream && !isCameraOff;

    // Which feed is full screen vs the small draggable preview.
    final fullRenderer = _previewSwapped ? c.localRenderer : c.remoteRenderer;
    final previewRenderer =
        _previewSwapped ? c.remoteRenderer : c.localRenderer;
    final isPreviewLocal = !_previewSwapped;
    final fullHasStream =
        _previewSwapped ? (hasLocalStream && !isCameraOff) : hasRemoteStream;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: CustomColor.kDarkBackground),
        ),
        if (fullHasStream)
          Positioned.fill(
            child: RTCVideoView(
              fullRenderer,
              key: ValueKey('full_video'),
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: _previewSwapped,
            ),
          ),
        if ((!hasRemoteStream && !_previewSwapped) || !isConnected)
          _buildPlaceholder(c, callState),
        _buildTopOverlay(c, callState),
        _buildLocalPreview(c, topPadding, fullHasStream, previewRenderer,
            isPreviewLocal, showLocalCamera),
        _buildVideoControlBar(c),
      ],
    );
  }

  Widget _buildPlaceholder(CallController c, String callState) {
    return Positioned.fill(
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContactAvatar(
                userId: c.otherUserId.value,
                radius: 52.r,
              ),
              SizedBox(height: 18.h),
              if (callState == 'connecting' || callState == 'ringing')
                const _ConnectingDots()
              else
                Text(
                  _statusLabel(c),
                  style: AppTextStyles.bodyLg
                      .copyWith(color: CustomColor.kTextOnDarkSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopOverlay(CallController c, String callState) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CustomColor.kBlack.withValues(alpha: 0.55),
              Colors.transparent,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                children: [
                  _GlassIconButton(
                    semanticLabel: 'Minimise call',
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () {
                      if (c.callState.value == 'connected' ||
                          c.callState.value == 'ringing' ||
                          c.callState.value == 'connecting' ||
                          c.callState.value == 'reconnecting') {
                        c.showMiniCallOverlay();
                        c.markCallScreenClosed();
                        Get.back();
                      }
                    },
                  ),
                  const Spacer(),
                  _GlassSmallButton(
                    icon: Icons.cameraswitch_rounded,
                    onTap: c.flipCamera,
                  ),
                  SizedBox(width: 10.w),
                  _GlassSmallButton(
                    icon: Icons.person_add_rounded,
                    onTap: () {
                      CustomSnackbar.show(
                          title: 'Coming Soon',
                          message: 'Add participant will be available soon');
                    },
                  ),
                  SizedBox(width: 10.w),
                  _GlassSmallButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () {
                      CustomSnackbar.show(
                          title: 'Coming Soon',
                          message: 'In-call chat will be available soon');
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Obx(() => Text(
                    c.otherUserName.value,
                    style: AppTextStyles.headingLg
                        .copyWith(color: CustomColor.kTextOnDark),
                  )),
              SizedBox(height: 4.h),
              if (callState == 'connecting' || callState == 'ringing')
                const _ConnectingDots()
              else
                Obx(() => Text(
                      _statusLabel(c),
                      style: AppTextStyles.subtitle
                          .copyWith(color: CustomColor.kTextOnDarkSecondary),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalPreview(
      CallController c,
      double topPadding,
      bool fullHasStream,
      RTCVideoRenderer previewRenderer,
      bool isPreviewLocal,
      bool showLocalCamera) {
    // The small preview's "camera off" only applies when it shows the local feed.
    final showPreviewCamera = isPreviewLocal ? showLocalCamera : true;
    return Positioned(
      right: showPreviewCamera ? null : 16.w,
      left: showPreviewCamera ? _localVideoPosition.dx : null,
      top: showPreviewCamera ? _localVideoPosition.dy : topPadding + 100.h,
      child: GestureDetector(
        onPanUpdate: showPreviewCamera
            ? (details) {
                setState(() {
                  final size = MediaQuery.of(context).size;
                  final topInset = MediaQuery.of(context).padding.top;
                  final bottomInset = MediaQuery.of(context).padding.bottom;
                  final previewW = 108.w;
                  final previewH = 152.h;
                  final dx = (_localVideoPosition.dx + details.delta.dx)
                      .clamp(12.0, size.width - previewW - 12.0);
                  final dy = (_localVideoPosition.dy + details.delta.dy).clamp(
                      topInset + 12.0,
                      size.height - previewH - bottomInset - 12.0);
                  _localVideoPosition = Offset(dx, dy);
                });
              }
            : null,
        onTap: () {
          setState(() {
            _previewSwapped = !_previewSwapped;
            _localVideoPosition = Offset(
              MediaQuery.of(context).size.width - 116.w - 16.w,
              topPadding + 70.h,
            );
          });
        },
        child: Container(
          width: 108.w,
          height: 152.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CustomColor.kDarkSurface3, CustomColor.kDarkSurface],
            ),
            borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
            border: Border.all(
              color: CustomColor.kWhite.withValues(alpha: 0.20),
              width: 1.2,
            ),
            boxShadow: showPreviewCamera
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: showPreviewCamera
              ? RTCVideoView(
                  previewRenderer,
                  key: ValueKey('preview_video'),
                  mirror: isPreviewLocal,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              : Center(
                  child: _ContactAvatar(
                    userId: c.callerId.value,
                    radius: 30.r,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildVideoControlBar(CallController c) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              CustomColor.kScrim60,
              Colors.transparent,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          top: false,
          child: _GlassDock(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CallButton(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  isVideoMode: true,
                  onTap: () => _showMoreMenu(c),
                ),
                _CallButton(
                  icon: c.isCameraOff.value
                      ? Icons.videocam_off_rounded
                      : Icons.videocam_rounded,
                  label: 'Camera',
                  isActive: !c.isCameraOff.value,
                  isVideoMode: true,
                  onTap: c.toggleCamera,
                ),
                Obx(() => _CallButton(
                      icon: _getAudioRouteIcon(c.currentAudioRoute.value),
                      label: _getAudioRouteLabel(c.currentAudioRoute.value),
                      isActive: c.currentAudioRoute.value == AudioRoute.speaker,
                      isVideoMode: true,
                      onTap: () => _onAudioButtonTap(c),
                      onLongPress: () => c.toggleSpeaker(),
                    )),
                Obx(() => _CallButton(
                      icon: c.isMicMuted.value
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: 'Mute',
                      isActive: c.isMicMuted.value,
                      isVideoMode: true,
                      onTap: c.toggleMute,
                    )),
                _EndCallButton(
                  onTap: c.endCall,
                  isVideoMode: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════

/// Subtle "Secure call" indicator. Uses a neutral status text — no claims of
/// crypto beyond what the app actually provides.
class _SecureCallIndicator extends StatelessWidget {
  const _SecureCallIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          color: CustomColor.kTextOnDarkMuted,
          size: 14.r,
        ),
        SizedBox(width: 6.w),
        Text(
          'Secure call',
          style: AppTextStyles.bodySm
              .copyWith(color: CustomColor.kTextOnDarkMuted),
        ),
      ],
    );
  }
}

/// Floating glass dock used for the voice/video control panels.
class _GlassDock extends StatelessWidget {
  final Widget child;
  const _GlassDock({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomColor.kOverlay30,
            CustomColor.kOverlay20,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.rounded.r),
        border: Border.all(
          color: CustomColor.kWhite.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kScrim20,
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  final String userId;
  final double radius;

  const _ContactAvatar({required this.userId, required this.radius});

  @override
  Widget build(BuildContext context) {
    final image = _getContactImage(userId);
    return CircleAvatar(
      radius: radius,
      backgroundColor: CustomColor.kDarkSurface3,
      backgroundImage: image != null
          ? CachedNetworkImageProvider(image)
          : const AssetImage(AppAssets.defaultProfilePic) as ImageProvider,
      onBackgroundImageError: (_, __) {},
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  const _GlassIconButton({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 46.r,
          height: 46.r,
          decoration: BoxDecoration(
            color: CustomColor.kWhite.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: CustomColor.kWhite.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kScrim20,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: CustomColor.kTextOnDark,
            size: 24.r,
          ),
        ),
      ),
    );
  }
}

class _GlassSmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassSmallButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: CustomColor.kWhite.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(
            color: CustomColor.kWhite.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: CustomColor.kTextOnDark,
          size: 20.r,
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isVideoMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _CallButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.isVideoMode = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    if (isActive) {
      bgColor =
          isVideoMode ? CustomColor.kPrimaryColor : CustomColor.kPrimaryColor;
    } else {
      bgColor = CustomColor.kWhite.withValues(alpha: 0.10);
    }

    final Color iconColor =
        isActive ? CustomColor.kWhite : CustomColor.kTextOnDark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: isActive
                  ? null
                  : Border.all(
                      color: CustomColor.kWhite.withValues(alpha: 0.15),
                      width: 1,
                    ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22.r,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: AppTextStyles.labelSm
                .copyWith(color: CustomColor.kTextOnDarkSecondary),
          ),
        ],
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isVideoMode;

  const _EndCallButton({required this.onTap, this.isVideoMode = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isVideoMode ? 'End video call' : 'End call',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: isVideoMode ? 56.r : 60.r,
          height: isVideoMode ? 56.r : 60.r,
          decoration: BoxDecoration(
            color: CustomColor.kDangerRed,
            shape: BoxShape.circle,
            border: Border.all(
              color: CustomColor.kWhite.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kDangerRed.withValues(alpha: 0.4),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.call_end_rounded,
            color: CustomColor.kTextOnDark,
            size: isVideoMode ? 26.r : 28.r,
          ),
        ),
      ),
    );
  }
}

class _ConnectingDots extends StatefulWidget {
  const _ConnectingDots();

  @override
  State<_ConnectingDots> createState() => _ConnectingDotsState();
}

class _ConnectingDotsState extends State<_ConnectingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.3;
            final value = (_controller.value + delay) % 1.0;
            final opacity =
                0.2 + 0.8 * math.sin(value * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Container(
                width: 7.r,
                height: 7.r,
                decoration: BoxDecoration(
                  color: CustomColor.kPrimaryLight.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  final double animation;
  final Color color;

  _PulseRingPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 2; i++) {
      final phase = (animation + i * 0.5) % 1.0;
      final radius = maxRadius + phase * 24;
      final opacity = (1.0 - phase) * 0.18;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulseRingPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

// ══════════════════════════════════════════════════════════════════════════
// AUDIO ROUTE SHEET
// ══════════════════════════════════════════════════════════════════════════

void _showAudioRouteSheet(CallController controller) {
  showModalBottomSheet(
    context: Get.context!,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      return _SheetShell(
        bottomPadding: bottomPadding,
        title: 'Audio Output',
        onClose: () => Navigator.pop(context),
        child: Obx(() {
          final routes = controller.availableAudioRoutes;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (routes.contains(AudioRoute.earpiece))
                _AudioRouteOption(
                  icon: Icons.phone_rounded,
                  label: 'Phone',
                  subtitle: 'Earpiece',
                  isSelected:
                      controller.currentAudioRoute.value == AudioRoute.earpiece,
                  onTap: () {
                    controller.setAudioRoute(AudioRoute.earpiece);
                    Navigator.pop(context);
                  },
                ),
              if (routes.contains(AudioRoute.speaker))
                _AudioRouteOption(
                  icon: Icons.volume_up_rounded,
                  label: 'Speaker',
                  subtitle: 'Loud speaker',
                  isSelected:
                      controller.currentAudioRoute.value == AudioRoute.speaker,
                  onTap: () {
                    controller.setAudioRoute(AudioRoute.speaker);
                    Navigator.pop(context);
                  },
                ),
              if (routes.contains(AudioRoute.bluetooth))
                _AudioRouteOption(
                  icon: Icons.bluetooth_rounded,
                  label: 'Bluetooth',
                  subtitle: 'Bluetooth audio',
                  isSelected: controller.currentAudioRoute.value ==
                      AudioRoute.bluetooth,
                  onTap: () {
                    controller.setAudioRoute(AudioRoute.bluetooth);
                    Navigator.pop(context);
                  },
                ),
              if (routes.contains(AudioRoute.headset))
                _AudioRouteOption(
                  icon: Icons.headset_rounded,
                  label: 'Headset',
                  subtitle: 'Wired headset',
                  isSelected:
                      controller.currentAudioRoute.value == AudioRoute.headset,
                  onTap: () {
                    controller.setAudioRoute(AudioRoute.headset);
                    Navigator.pop(context);
                  },
                ),
              SizedBox(height: 8.h),
            ],
          );
        }),
      );
    },
  );
}

class _AudioRouteOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _AudioRouteOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                color: isSelected
                    ? CustomColor.kPrimaryColor.withValues(alpha: 0.20)
                    : CustomColor.kWhite.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? CustomColor.kPrimaryLight
                    : CustomColor.kTextOnDarkSecondary,
                size: 20.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: CustomColor.kTextOnDark),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: CustomColor.kTextOnDarkMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: CustomColor.kPrimaryColor,
                size: 20.r,
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// MORE MENU SHEET
// ══════════════════════════════════════════════════════════════════════════

void _showMoreMenu(CallController controller) {
  showModalBottomSheet(
    context: Get.context!,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      return _SheetShell(
        bottomPadding: bottomPadding,
        title: 'Call Options',
        onClose: () => Navigator.pop(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoreMenuItem(
              icon: Icons.volume_up_rounded,
              label: 'Audio Output',
              subtitle: _getAudioRouteLabel(controller.currentAudioRoute.value),
              onTap: () {
                Navigator.pop(context);
                _showAudioRouteSheet(controller);
              },
            ),
            Obx(() {
              if (controller.callType.value == 'video') {
                return _MoreMenuItem(
                  icon: Icons.cameraswitch_rounded,
                  label: 'Switch Camera',
                  onTap: () {
                    Navigator.pop(context);
                    controller.flipCamera();
                  },
                );
              }
              return const SizedBox.shrink();
            }),
            _MoreMenuItem(
              icon: Icons.person_add_rounded,
              label: 'Add Participant',
              isAvailable: false,
              onTap: () {
                Navigator.pop(context);
                CustomSnackbar.show(
                    title: 'Coming Soon',
                    message: 'Add participant will be available soon');
              },
            ),
            _MoreMenuItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              isAvailable: false,
              onTap: () {
                Navigator.pop(context);
                CustomSnackbar.show(
                    title: 'Coming Soon',
                    message: 'In-call chat will be available soon');
              },
            ),
            _MoreMenuItem(
              icon: Icons.screen_share_rounded,
              label: 'Share Screen',
              isAvailable: false,
              onTap: () {
                Navigator.pop(context);
                CustomSnackbar.show(
                    title: 'Coming Soon',
                    message: 'Screen sharing will be available soon');
              },
            ),
            _MoreMenuItem(
              icon: Icons.info_outline_rounded,
              label: 'Call Information',
              onTap: () {
                Navigator.pop(context);
                _showCallInfo(controller);
              },
            ),
            _MoreMenuItem(
              icon: Icons.flag_outlined,
              label: 'Report / Block',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showReportBlockSheet(controller);
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      );
    },
  );
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool isAvailable;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.isAvailable = true,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive
        ? CustomColor.kDangerRed
        : (isAvailable
            ? CustomColor.kTextOnDark
            : CustomColor.kTextOnDarkMuted);
    final textColor = isDestructive
        ? CustomColor.kDangerRed
        : (isAvailable
            ? CustomColor.kTextOnDark
            : CustomColor.kTextOnDarkMuted);

    return InkWell(
      onTap: isAvailable ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 13.h),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20.r),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMd.copyWith(color: textColor),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption
                          .copyWith(color: CustomColor.kTextOnDarkMuted),
                    ),
                ],
              ),
            ),
            if (!isAvailable)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: CustomColor.kWhite.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                ),
                child: Text(
                  'Soon',
                  style: AppTextStyles.labelSm
                      .copyWith(color: CustomColor.kTextOnDarkMuted),
                ),
              ),
            if (isAvailable && !isDestructive)
              Icon(
                Icons.chevron_right_rounded,
                color: CustomColor.kTextOnDarkMuted,
                size: 18.r,
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CALL INFO SHEET
// ══════════════════════════════════════════════════════════════════════════

void _showCallInfo(CallController controller) {
  showModalBottomSheet(
    context: Get.context!,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      return _SheetShell(
        bottomPadding: bottomPadding,
        title: 'Call Information',
        onClose: () => Navigator.pop(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InfoRow(label: 'Name', value: controller.otherUserName.value),
            _InfoRow(
              label: 'Type',
              value: controller.callType.value == 'video'
                  ? 'Video Call'
                  : 'Voice Call',
            ),
            _InfoRow(label: 'Duration', value: controller.formattedDuration),
            _InfoRow(label: 'Status', value: _statusLabel(controller)),
            SizedBox(height: 20.h),
          ],
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.subtitle
                .copyWith(color: CustomColor.kTextOnDarkSecondary),
          ),
          Text(
            value,
            style:
                AppTextStyles.subtitle.copyWith(color: CustomColor.kTextOnDark),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// REPORT / BLOCK SHEET
// ══════════════════════════════════════════════════════════════════════════

void _showReportBlockSheet(CallController controller) {
  showModalBottomSheet(
    context: Get.context!,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      return _SheetShell(
        bottomPadding: bottomPadding,
        title: 'Report / Block',
        onClose: () => Navigator.pop(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MoreMenuItem(
              icon: Icons.flag_outlined,
              label: 'Report User',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                CustomSnackbar.show(
                    title: 'Reported', message: 'User has been reported');
              },
            ),
            _MoreMenuItem(
              icon: Icons.block_rounded,
              label: 'Block User',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                controller.endCall();
                CustomSnackbar.show(
                    title: 'Blocked', message: 'User has been blocked');
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      );
    },
  );
}

/// Shared dark glass bottom-sheet container.
class _SheetShell extends StatelessWidget {
  final double bottomPadding;
  final String title;
  final VoidCallback onClose;
  final Widget child;

  const _SheetShell({
    required this.bottomPadding,
    required this.title,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h + bottomPadding),
      decoration: BoxDecoration(
        color: CustomColor.kDarkSurface,
        borderRadius: BorderRadius.circular(AppRadius.rounded.r),
        border: Border.all(
          color: CustomColor.kWhite.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Container(
              width: 36.r,
              height: 4.r,
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDarkMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.pill.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
            child: Row(
              children: [
                Text(
                  title,
                  style: AppTextStyles.headingSm
                      .copyWith(color: CustomColor.kTextOnDark),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(
                    Icons.close_rounded,
                    color: CustomColor.kTextOnDarkSecondary,
                    size: 22.r,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════

String _statusLabel(CallController controller) {
  switch (controller.callState.value) {
    case 'ringing':
      return controller.iAmCaller ? 'Calling...' : 'Ringing...';
    case 'connecting':
      return 'Connecting...';
    case 'connected':
      return controller.formattedDuration;
    case 'reconnecting':
      return 'Reconnecting...';
    default:
      return 'Call ended';
  }
}

String? _getContactImage(String userId) {
  final user = LocalDatabase.getUser(userId);
  if (user?.userImage?.isNotEmpty == true) {
    return '${Endpoints.mediaBaseUrl}${user!.userImage}';
  }
  return null;
}

void _onAudioButtonTap(CallController controller) {
  if (controller.hasExternalAudioDevices) {
    // External device present — show the selector limited to available routes.
    _showAudioRouteSheet(controller);
  } else {
    // Only earpiece + speaker — simple reliable toggle.
    controller.cycleAudioOutput();
  }
}

IconData _getAudioRouteIcon(AudioRoute route) {
  switch (route) {
    case AudioRoute.speaker:
      return Icons.volume_up_rounded;
    case AudioRoute.bluetooth:
      return Icons.bluetooth_rounded;
    case AudioRoute.headset:
      return Icons.headset_rounded;
    case AudioRoute.earpiece:
      return Icons.phone_rounded;
  }
}

String _getAudioRouteLabel(AudioRoute route) {
  switch (route) {
    case AudioRoute.speaker:
      return 'Speaker';
    case AudioRoute.bluetooth:
      return 'Bluetooth';
    case AudioRoute.headset:
      return 'Headset';
    case AudioRoute.earpiece:
      return 'Phone';
  }
}
