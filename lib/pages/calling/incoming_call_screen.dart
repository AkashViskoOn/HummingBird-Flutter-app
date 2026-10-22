import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: CustomColor.kDarkBackground,
        body: Container(
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
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final avatarSize =
                    (constraints.maxHeight * 0.22).clamp(96.0, 132.0);
                return Column(
                  children: [
                    // ---- Top: call type badge ----
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 0),
                      child: Obx(() => _CallTypeChip(
                            isVideo: controller.callType.value == 'video',
                          )),
                    ),
                    // ---- Center: avatar + caller name + status ----
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(() {
                                final image = _getContactImage(
                                    controller.otherUserId.value);
                                return _PulsingAvatar(
                                    image: image, size: avatarSize);
                              }),
                              SizedBox(height: 28.h),
                              Obx(() => Text(
                                    controller.otherUserName.value,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.displayLarge.copyWith(
                                        color: CustomColor.kTextOnDark),
                                  )),
                              SizedBox(height: 10.h),
                              Obx(() => Text(
                                    controller.callType.value == 'video'
                                        ? 'Incoming video call'
                                        : 'Incoming voice call',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodyLg.copyWith(
                                        color:
                                            CustomColor.kTextOnDarkSecondary),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // ---- Bottom: Decline / Accept ----
                    _IncomingActions(controller: controller),
                  ],
                );
              },
            ),
          ),
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

class _CallTypeChip extends StatelessWidget {
  final bool isVideo;
  const _CallTypeChip({required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: CustomColor.kDarkSurface2.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
        border: Border.all(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVideo ? Icons.videocam_rounded : Icons.phone_in_talk_rounded,
            color: CustomColor.kPrimaryLight,
            size: 18.r,
          ),
          SizedBox(width: 8.w),
          Text(
            isVideo ? 'Incoming video call' : 'Incoming voice call',
            style: AppTextStyles.label.copyWith(color: CustomColor.kTextOnDark),
          ),
        ],
      ),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  final String? image;
  final double size;
  const _PulsingAvatar({required this.image, required this.size});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulse.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [CustomColor.kPrimaryColor, CustomColor.kPrimaryMedium],
              ),
              boxShadow: [
                BoxShadow(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: EdgeInsets.all(3.r),
            child: CircleAvatar(
              radius: (widget.size / 2) - 3.r,
              backgroundColor: CustomColor.kDarkSurface3,
              backgroundImage: widget.image != null
                  ? CachedNetworkImageProvider(widget.image!)
                  : const AssetImage(AppAssets.defaultProfilePic)
                      as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
          ),
        );
      },
    );
  }
}

class _IncomingActions extends StatelessWidget {
  final CallController controller;
  const _IncomingActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 20.h),
      child: Row(
        children: [
          Expanded(
            child: _CallActionButton(
              icon: Icons.call_end_rounded,
              label: 'Decline',
              color: CustomColor.kDangerRed,
              onTap: () {
                HapticFeedback.mediumImpact();
                controller.rejectCall(controller.callSessionId.value);
              },
            ),
          ),
          SizedBox(width: 64.w),
          Expanded(
            child: Obx(() => _CallActionButton(
                  icon: controller.callType.value == 'video'
                      ? Icons.videocam_rounded
                      : Icons.phone_rounded,
                  label: 'Accept',
                  color: CustomColor.kOnlineGreen,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.answerCall(controller.callSessionId.value);
                  },
                )),
          ),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: 0.92,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68.r,
              height: 68.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 26,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: CustomColor.kWhite, size: 30.r),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style:
                  AppTextStyles.label.copyWith(color: CustomColor.kTextOnDark),
            ),
          ],
        ),
      ),
    );
  }
}
