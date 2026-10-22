import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/connectivity/pulsing_dot.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/connectivity_service.dart';
import 'package:humming_bird/services/offline_queue_service.dart';
import 'package:humming_bird/services/retry_queue_service.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Polished "Connection Info" screen. Every value is derived from the EXISTING
/// application state:
///  - Live connection: [ChatController.socketConnectionState] (fed by the
///    existing socket callbacks — never simulated).
///  - Internet / Network: [ConnectivityService] (platform connectivity_plus).
///  - Messages sync: existing [OfflineQueueService] / [RetryQueueService].
///  - FCM: real FirebaseMessaging authorization + token state.
/// Anything with no existing source shows "Not available" — no fake values.
class ConnectionInfoScreen extends StatefulWidget {
  const ConnectionInfoScreen({super.key});

  @override
  State<ConnectionInfoScreen> createState() => _ConnectionInfoScreenState();
}

class _ConnectionInfoScreenState extends State<ConnectionInfoScreen> {
  String _fcmLabel = 'Not available';

  @override
  void initState() {
    super.initState();
    _loadFcm();
  }

  Future<void> _loadFcm() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final token = await FirebaseMessaging.instance.getToken();
      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      final active = authorized && (token?.isNotEmpty ?? false);
      if (!mounted) return;
      setState(() => _fcmLabel = active ? 'Active' : 'Not available');
    } catch (_) {
      if (!mounted) return;
      setState(() => _fcmLabel = 'Not available');
    }
  }

  void _retryConnection() {
    ConnectivityService.to.refresh();
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().retryConnection();
    }
    _loadFcm();
    Utils.showGetSnackBar('Retrying connection…');
  }

  void _refreshStatus() {
    ConnectivityService.to.refresh();
    _loadFcm();
    Utils.showGetSnackBar('Connection status refreshed');
  }

  String get _socketLiveLabel {
    if (!Get.isRegistered<ChatController>()) return 'Not available';
    return switch (Get.find<ChatController>().socketConnectionState.value) {
      SocketConnectionState.connected => 'Live connection active',
      SocketConnectionState.connecting => 'Connecting to Humming Bird…',
      SocketConnectionState.reconnecting => 'Trying to reconnect…',
      SocketConnectionState.disconnected => 'Live connection unavailable',
    };
  }

  String get _socketStatusLabel {
    if (!Get.isRegistered<ChatController>()) return 'Not available';
    return switch (Get.find<ChatController>().socketConnectionState.value) {
      SocketConnectionState.connected => 'Connected',
      SocketConnectionState.connecting => 'Connecting…',
      SocketConnectionState.reconnecting => 'Reconnecting…',
      SocketConnectionState.disconnected => 'Disconnected',
    };
  }

  Color get _socketColor {
    if (!Get.isRegistered<ChatController>()) return CustomColor.kTextTertiary;
    return switch (Get.find<ChatController>().socketConnectionState.value) {
      SocketConnectionState.connected => CustomColor.kPrimaryColor,
      SocketConnectionState.connecting => CustomColor.kPrimaryMedium,
      SocketConnectionState.reconnecting => CustomColor.kGoldAccent,
      SocketConnectionState.disconnected => CustomColor.kTextTertiary,
    };
  }

  String get _networkLabel {
    final type = ConnectivityService.to.connectionType.value;
    if (type == null) return 'Not available';
    return switch (type) {
      ConnectivityResult.wifi => 'Wi-Fi',
      ConnectivityResult.mobile => 'Mobile Data',
      ConnectivityResult.ethernet => 'Ethernet',
      ConnectivityResult.vpn => 'VPN',
      ConnectivityResult.bluetooth => 'Bluetooth',
      ConnectivityResult.satellite => 'Satellite',
      ConnectivityResult.other => 'Other network',
      ConnectivityResult.none => 'No connection',
    };
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        dark ? CustomColor.kDarkBackground : CustomColor.kBackground;
    final cardColor =
        dark ? CustomColor.kDarkSurface : CustomColor.kLightSurface;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: CommonAppBar(title: 'Connection'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            child: Entrance(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Humming Bird connection status',
                    style: (dark
                        ? AppTextStyles.bodySmOnDark
                        : AppTextStyles.bodySm),
                  ),
                  SizedBox(height: 16.h),
                  _HeroStatus(cardColor: cardColor, dark: dark),
                  SizedBox(height: 18.h),
                  _InfoCard(
                    dark: dark,
                    cardColor: cardColor,
                    title: 'Live connection',
                    rows: [
                      _InfoRow(
                        dark: dark,
                        label: 'Status',
                        leading: PulsingDot(color: _socketColor, size: 8.r),
                        value: _socketStatusLabel,
                        valueColor: _socketColor,
                      ),
                      _InfoRow(
                        dark: dark,
                        label: 'Socket',
                        leading: PulsingDot(color: _socketColor, size: 8.r),
                        value: _socketStatusLabel,
                        valueColor: _socketColor,
                      ),
                      _InfoRow(
                        dark: dark,
                        label: 'Detail',
                        value: _socketLiveLabel,
                        valueColor: _socketColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Obx(
                    () => _InfoCard(
                      dark: dark,
                      cardColor: cardColor,
                      title: 'Internet',
                      rows: [
                        _InfoRow(
                          dark: dark,
                          label: 'Status',
                          leading: PulsingDot(
                            color: ConnectivityService.to.isOnline.value
                                ? CustomColor.kOnlineGreen
                                : CustomColor.kDangerRed,
                            size: 8.r,
                          ),
                          value: ConnectivityService.to.isOnline.value
                              ? 'Online'
                              : 'Offline',
                          valueColor: ConnectivityService.to.isOnline.value
                              ? CustomColor.kOnlineGreen
                              : CustomColor.kDangerRed,
                        ),
                        _InfoRow(
                          dark: dark,
                          label: 'Network',
                          value: _networkLabel,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Obx(
                    () => _InfoCard(
                      dark: dark,
                      cardColor: cardColor,
                      title: 'Messages',
                      rows: [
                        _InfoRow(
                          dark: dark,
                          label: 'Sync status',
                          leading: PulsingDot(
                            color: _hasPendingSync
                                ? CustomColor.kGoldAccent
                                : CustomColor.kPrimaryColor,
                            size: 8.r,
                          ),
                          value: _hasPendingSync
                              ? '$_pendingTotal pending — will sync when online'
                              : 'Up to date',
                          valueColor: _hasPendingSync
                              ? CustomColor.kGoldAccent
                              : CustomColor.kPrimaryColor,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _InfoCard(
                    dark: dark,
                    cardColor: cardColor,
                    title: 'Notifications',
                    rows: [
                      _InfoRow(
                        dark: dark,
                        label: 'FCM',
                        leading: PulsingDot(
                          color: _fcmLabel == 'Active'
                              ? CustomColor.kOnlineGreen
                              : CustomColor.kTextTertiary,
                          size: 8.r,
                        ),
                        value: _fcmLabel,
                        valueColor: _fcmLabel == 'Active'
                            ? CustomColor.kOnlineGreen
                            : CustomColor.kTextTertiary,
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  _InfoCard(
                    dark: dark,
                    cardColor: cardColor,
                    title: 'Last sync',
                    rows: [
                      _InfoRow(
                        dark: dark,
                        label: 'Last sync',
                        value: 'Not available',
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  AppButton(
                    text: 'Retry connection',
                    onTap: _retryConnection,
                    buttonIcon: const Icon(Icons.refresh_rounded,
                        color: CustomColor.kTextOnDark, size: 18),
                  ),
                  SizedBox(height: 10.h),
                  AppButton(
                    text: 'Refresh connection status',
                    onTap: _refreshStatus,
                    variant: AppButtonVariant.outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int get _pendingTotal {
    int pending = 0;
    try {
      if (Get.isRegistered<OfflineQueueService>()) {
        pending += OfflineQueueService.to.pendingMessages.value;
      }
      if (Get.isRegistered<RetryQueueService>()) {
        pending += RetryQueueService.to.pendingCount.value;
      }
    } catch (_) {}
    return pending;
  }

  bool get _hasPendingSync => _pendingTotal > 0;
}

class _HeroStatus extends StatelessWidget {
  final Color cardColor;
  final bool dark;

  const _HeroStatus({required this.cardColor, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final online = ConnectivityService.to.isOnline.value;
      final socketState = Get.isRegistered<ChatController>()
          ? Get.find<ChatController>().socketConnectionState.value
          : null;
      if (socketState == null || !online) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: _buildDecoration(),
          child: Row(
            children: [
              PulsingDot(
                color: online
                    ? CustomColor.kPrimaryMedium
                    : CustomColor.kDangerRed,
                size: 12.r,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      online ? 'Not available' : 'Offline',
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: CustomColor.kTextOnDark,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      online
                          ? 'Live state is not ready yet'
                          : "You're offline — messages will sync when you're back online.",
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: dark
                            ? CustomColor.kTextOnDarkMuted
                            : CustomColor.kOverlay70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      final socketConnected = socketState == SocketConnectionState.connected;
      final (title, subtitle) = socketConnected
          ? ('Connected', 'Live connection active')
          : (
              switch (socketState) {
                SocketConnectionState.connecting => 'Connecting…',
                SocketConnectionState.reconnecting => 'Reconnecting…',
                SocketConnectionState.disconnected => 'Disconnected',
                SocketConnectionState.connected => 'Connected',
              },
              switch (socketState) {
                SocketConnectionState.connecting =>
                  'Connecting to Humming Bird…',
                SocketConnectionState.reconnecting => 'Trying to reconnect…',
                SocketConnectionState.disconnected =>
                  'Live connection unavailable',
                SocketConnectionState.connected => 'Live connection active',
              }
            );

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: _buildDecoration(),
        child: Row(
          children: [
            PulsingDot(color: CustomColor.kTextOnDark, size: 12.r),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: CustomColor.kTextOnDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w400,
                      color: dark
                          ? CustomColor.kTextOnDarkMuted
                          : CustomColor.kOverlay70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      gradient: dark
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CustomColor.kDarkSurface2, CustomColor.kDarkSurface3],
            )
          : CustomColor.primaryGradient,
      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
      border: dark ? Border.all(color: CustomColor.kOverlay8) : null,
      boxShadow: [
        BoxShadow(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.28),
          blurRadius: 20.r,
          offset: Offset(0, 8.h),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  final bool dark;
  final Color cardColor;

  const _InfoCard({
    required this.title,
    required this.rows,
    required this.dark,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        border: Border.all(
          color: dark ? CustomColor.kOverlay6 : CustomColor.kLightBorder,
        ),
        boxShadow: dark
            ? []
            : [
                BoxShadow(
                  color: CustomColor.kBlack.withValues(alpha: 0.05),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: dark
                  ? CustomColor.kTextOnDarkMuted
                  : CustomColor.kTextTertiary,
            ),
          ),
          SizedBox(height: 10.h),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? leading;
  final Color? valueColor;
  final bool dark;

  const _InfoRow({
    required this.label,
    required this.value,
    this.leading,
    this.valueColor,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: 10.w),
          ] else
            SizedBox(width: 18.w),
          Expanded(
            child: Text(
              label,
              style: (dark ? AppTextStyles.bodySmOnDark : AppTextStyles.bodySm)
                  .copyWith(fontSize: 12.sp),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style:
                  (dark ? AppTextStyles.titleMdOnDark : AppTextStyles.titleSm)
                      .copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (dark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
