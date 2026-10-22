import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/connectivity/pulsing_dot.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/connectivity_service.dart';
import 'package:humming_bird/services/offline_queue_service.dart';
import 'package:humming_bird/services/retry_queue_service.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// A compact, reusable live connection status bar.
///
/// It never fabricates state — every value comes from the real sources:
///   - device connectivity  -> [ConnectivityService.isOnline]
///   - live socket state     -> [ChatController.socketConnectionState]
///   - pending sync work     -> [OfflineQueueService.pendingMessages] +
///                              [RetryQueueService.pendingCount]
///
/// Healthy (online + socket connected + no pending work): a slim quiet pill.
/// Any issue expands into a fuller state (offline / syncing / reconnecting /
/// unavailable) with an optional tap-through action (retry / refresh).
class ConnectionStatusBar extends StatelessWidget {
  /// Show the secondary line (e.g. "Live connection active"). When false the
  /// bar collapses to a single-line compact strip.
  final bool showSubtitle;

  const ConnectionStatusBar({super.key, this.showSubtitle = true});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final online = ConnectivityService.to.isOnline.value;
      final pending = OfflineQueueService.to.pendingMessages.value +
          RetryQueueService.to.pendingCount.value;

      SocketConnectionState? socketState;
      if (Get.isRegistered<ChatController>()) {
        socketState = Get.find<ChatController>().socketConnectionState.value;
      }

      _StatusData status;
      if (!online) {
        status = _StatusData(
          color: CustomColor.kWarning,
          title: "You're offline",
          subtitle: 'Messages will sync when you’re back online',
          onTap: ConnectivityService.to.refresh,
        );
      } else if (pending > 0) {
        status = _StatusData(
          color: CustomColor.kPrimaryColor,
          title: 'Syncing messages…',
          subtitle: 'Synchronizing $pending item${pending == 1 ? '' : 's'}',
          syncing: true,
        );
      } else if (socketState == SocketConnectionState.connecting) {
        status = _StatusData(
          color: CustomColor.kPrimaryMedium,
          title: 'Connecting…',
          subtitle: 'Establishing connection',
        );
      } else if (socketState == SocketConnectionState.reconnecting) {
        status = _StatusData(
          color: CustomColor.kWarning,
          title: 'Reconnecting…',
          subtitle: 'Trying to reconnect',
        );
      } else if (socketState == SocketConnectionState.disconnected) {
        status = _StatusData(
          color: CustomColor.kDangerRed,
          title: 'Connection unavailable',
          subtitle: 'Retry connection',
          onTap: () {
            if (Get.isRegistered<ChatController>()) {
              Get.find<ChatController>().retryConnection();
            }
          },
        );
      } else {
        status = _StatusData(
          color: CustomColor.kSuccess,
          title: 'Connected',
          subtitle: 'Live connection active',
        );
      }

      final showSub =
          showSubtitle && (status.subtitle != null || status.syncing);
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
        child: AnimatedSize(
          duration: AppAnimation.fast,
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            onTap: status.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppAnimation.fast,
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: showSub ? 10.h : 8.h),
              decoration: BoxDecoration(
                color: CustomColor.kTextOnDark,
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                border: Border.all(
                    color: CustomColor.kLightBorder.withValues(alpha: 0.9)),
              ),
              child: Row(
                children: [
                  PulsingDot(color: status.color, size: 8.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subtitle
                              .copyWith(color: CustomColor.kTextPrimary),
                        ),
                        if (showSub) ...[
                          SizedBox(height: 1.h),
                          Text(
                            _subtitleFor(status),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.error
                                .copyWith(color: CustomColor.kTextSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (status.syncing)
                    SizedBox(
                      width: 14.r,
                      height: 14.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: status.color,
                      ),
                    )
                  else if (status.onTap != null)
                    Icon(Icons.chevron_right_rounded,
                        color: CustomColor.kTextTertiary, size: 18.r),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _subtitleFor(_StatusData status) {
    if (status.syncing) return status.subtitle ?? 'Catching up securely…';
    return status.subtitle ?? '';
  }
}

class _StatusData {
  final Color color;
  final String title;
  final String? subtitle;
  final bool syncing;
  final VoidCallback? onTap;

  const _StatusData({
    required this.color,
    required this.title,
    this.subtitle,
    this.syncing = false,
    this.onTap,
  });
}
