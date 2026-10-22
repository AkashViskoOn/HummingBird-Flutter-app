import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/connectivity/pulsing_dot.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/connectivity_service.dart';
import 'package:humming_bird/services/offline_queue_service.dart';
import 'package:humming_bird/services/retry_queue_service.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Global premium connectivity pill rendered above every screen.
///
/// Only the INTERNET state drives this banner (real platform connectivity from
/// [ConnectivityService]). Socket live-state is surfaced on the chat surface,
/// and the full picture lives in the Connection Info screen.
///
/// States:
///  - offline: dark pill, "You're offline" + sync promise, stays until back.
///  - back online: green pulse, then a "Syncing messages…" pill whenever the
///    EXISTING offline/retry queues still hold pending work, which auto-hides
///    when the queue drains (real drain observation — never simulated).
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  static const Duration _backOnlineHold = Duration(milliseconds: 1400);
  static const Duration _syncCap = Duration(seconds: 6);

  Worker? _onlineWorker;
  Worker? _offlineQueueWorker;
  Worker? _retryQueueWorker;
  Timer? _backOnlineTimer;
  Timer? _syncCapTimer;
  bool _wasOnline = true;
  bool _showBackOnline = false;
  bool _showSyncing = false;

  bool get _hasPendingWork {
    try {
      if (Get.isRegistered<OfflineQueueService>() &&
          OfflineQueueService.to.pendingMessages.value > 0) {
        return true;
      }
      if (Get.isRegistered<RetryQueueService>() &&
          RetryQueueService.to.pendingCount.value > 0) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  bool get _connectivityAvailable => Get.isRegistered<ConnectivityService>();

  @override
  void initState() {
    super.initState();
    if (!_connectivityAvailable) {
      _wasOnline = true;
      return;
    }

    _wasOnline = ConnectivityService.to.isOnline.value;
    _onlineWorker =
        ever<bool>(ConnectivityService.to.isOnline, _handleOnlineChange);

    if (Get.isRegistered<OfflineQueueService>()) {
      _offlineQueueWorker = ever<int>(OfflineQueueService.to.pendingMessages,
          (_) => _handlePendingChange());
    }
    if (Get.isRegistered<RetryQueueService>()) {
      _retryQueueWorker = ever<int>(
          RetryQueueService.to.pendingCount, (_) => _handlePendingChange());
    }
  }

  void _handleOnlineChange(bool online) {
    if (!mounted) return;
    if (!online) {
      _backOnlineTimer?.cancel();
      _syncCapTimer?.cancel();
      setState(() {
        _showBackOnline = false;
        _showSyncing = false;
        _wasOnline = false;
      });
    } else if (!_wasOnline) {
      _backOnlineTimer?.cancel();
      _syncCapTimer?.cancel();
      setState(() {
        _showBackOnline = true;
        _showSyncing = false;
        _wasOnline = true;
      });
      _backOnlineTimer = Timer(_backOnlineHold, () {
        if (!mounted) return;
        if (_hasPendingWork) {
          setState(() {
            _showBackOnline = false;
            _showSyncing = true;
          });
          _syncCapTimer = Timer(_syncCap, () {
            if (!mounted) return;
            setState(() => _showSyncing = false);
          });
        } else {
          setState(() {
            _showBackOnline = false;
            _showSyncing = false;
          });
        }
      });
    }
  }

  void _handlePendingChange() {
    if (!mounted) return;
    if (_showSyncing && !_hasPendingWork) {
      _syncCapTimer?.cancel();
      setState(() => _showSyncing = false);
    }
  }

  @override
  void dispose() {
    _onlineWorker?.dispose();
    _offlineQueueWorker?.dispose();
    _retryQueueWorker?.dispose();
    _backOnlineTimer?.cancel();
    _syncCapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_connectivityAvailable) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final online = ConnectivityService.to.isOnline.value;
      final showOffline = !online;
      final visible = showOffline || _showBackOnline || _showSyncing;

      return AnimatedSwitcher(
        duration: AppAnimation.medium,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => SharedAxisTransition(
          transitionType: SharedAxisTransitionType.vertical,
          animation: animation,
          secondaryAnimation: kAlwaysDismissedAnimation,
          fillColor: Colors.transparent,
          child: child,
        ),
        child: !visible
            ? const SizedBox(width: double.infinity, key: ValueKey('hidden'))
            : _Pill(
                key: ValueKey(showOffline
                    ? 'offline'
                    : _showBackOnline
                        ? 'back'
                        : 'syncing'),
                icon: showOffline
                    ? Icons.wifi_off_rounded
                    : _showBackOnline
                        ? Icons.wifi_rounded
                        : Icons.sync_rounded,
                dotColor: showOffline
                    ? CustomColor.kDangerRed
                    : _showBackOnline
                        ? CustomColor.kOnlineGreen
                        : CustomColor.kPrimaryColor,
                title: showOffline
                    ? "You're offline"
                    : _showBackOnline
                        ? 'Back online'
                        : 'Syncing messages…',
                subtitle: showOffline
                    ? "Messages will sync when you're back online."
                    : _showBackOnline
                        ? 'Connection restored'
                        : 'Catching up securely…',
                showSpinner: _showSyncing,
              ),
      );
    });
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color dotColor;
  final String title;
  final String subtitle;
  final bool showSpinner;

  const _Pill({
    super.key,
    required this.icon,
    required this.dotColor,
    required this.title,
    required this.subtitle,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CustomColor.kDarkSurface2,
              CustomColor.kDarkSurface3,
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          border: Border.all(
              color: CustomColor.kTextOnDark.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22.r,
              height: 22.r,
              child: showSpinner
                  ? SizedBox(
                      width: 15.r,
                      height: 15.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: dotColor,
                      ),
                    )
                  : PulsingDot(color: dotColor, size: 8.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySm
                        .copyWith(color: CustomColor.kTextOnDark),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm
                          .copyWith(color: CustomColor.kTextOnDarkMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
