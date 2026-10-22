import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/controllers/link_device_controller.dart';
import 'package:humming_bird/models/linked_device_model.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Settings -> Linked devices.
///
/// Shows the devices actually linked to this account, straight from
/// `GET /user/linked-devices`, and scans a desktop's pairing code.
///
/// Two things this screen deliberately does NOT do, because the server cannot
/// support them:
///   * badge a row as "this device" — a phone JWT has no `device_id` claim and
///     the list payload has no `is_current`, so there is nothing truthful to
///     compare against;
///   * show a QR code of its own — a phone is the thing that SCANS, and the
///     previous version displayed a static `assets/images/qr_code.jpg` as if it
///     were a live pairing request.
class LinkDeviceScreen extends StatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  State<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends State<LinkDeviceScreen> {
  final LinkDeviceController controller = Get.put(LinkDeviceController());

  @override
  void initState() {
    super.initState();
    controller.loadDevices();
  }

  @override
  void dispose() {
    // AGENTS.md: `Get.put` in `initState` hands back the OLD instance after a
    // re-login, which would leave a signed-in user looking at the previous
    // user's device list. Drop it with the screen.
    Get.delete<LinkDeviceController>();
    super.dispose();
  }

  IconData _platformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.desktop_mac;
      case 'linux':
        return Icons.computer;
      case 'mobile':
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      default:
        return Icons.devices;
    }
  }

  Future<void> _rename(LinkedDevice device) async {
    final textController = TextEditingController(text: device.deviceName ?? '');

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename device'),
        content: TextField(
          controller: textController,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Device name',
            helperText: 'How this device appears in Linked devices',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    textController.dispose();

    if (newName == null || newName.trim().isEmpty) return;
    await controller.renameDevice(device, newName);
  }

  Future<void> _revoke(LinkedDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out device'),
        content: Text(
          '"${device.displayName}" will be signed out immediately and will need to link again. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Sign out', style: TextStyle(color: CustomColor.kDangerRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.revokeDevice(device);
  }

  Future<void> _revokeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out all other devices'),
        content: const Text(
          'Every computer linked to your account will be signed out and will need to link again. '
          'Your phone stays signed in.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Sign out all', style: TextStyle(color: CustomColor.kDangerRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.revokeAllOtherDevices();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;

    return Scaffold(
      appBar: CommonAppBar(title: 'Linked devices'),
      body: RefreshIndicator(
        onRefresh: controller.loadDevices,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
          children: [
            _scanCard(isDark),
            SizedBox(height: 24.h),
            Obx(() => _sectionHeader(isDark)),
            Obx(() => _body(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _scanCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        boxShadow: AppShadow.cardLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 44.r,
            color: CustomColor.kPrimaryColor,
          ),
          SizedBox(height: 12.h),
          Text(
            'Link a computer',
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMd.copyWith(
              color: isDark ? CustomColor.kWhite : CustomColor.kTextPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'On your computer, choose "Connect Humming Bird" and it will show a QR code. '
            'Scan it here to sign that computer in.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(
              color: isDark ? CustomColor.kTextTertiary : CustomColor.kTextSecondary,
            ),
          ),
          SizedBox(height: 16.h),
          Obx(
            () => AppButton(
              text: 'Scan QR code',
              onTap: controller.isScanning.value ? null : controller.scanAndPair,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(bool isDark) {
    final hasDevices = controller.devices.isNotEmpty;
    final canRevokeAll = controller.devices.any((device) => !device.isRevoked);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connected devices',
          style: AppTextStyles.headingSm.copyWith(
            color: isDark ? CustomColor.kWhite : CustomColor.kTextPrimary,
          ),
        ),
        if (canRevokeAll) ...[
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _revokeAll,
            child: Text(
              'Sign out all other devices',
              style: AppTextStyles.bodySm.copyWith(
                color: CustomColor.kDangerRed,
                decoration: TextDecoration.underline,
                decorationColor: CustomColor.kDangerRed,
              ),
            ),
          ),
        ],
        if (!hasDevices && controller.loadError.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              'Showing nothing: ${controller.loadError.value}',
              style: AppTextStyles.helper,
            ),
          ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _body(bool isDark) {
    if (controller.isLoading.value && controller.devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CustomLoading(),
      );
    }

    // Distinguish "the request failed" from "you have no devices". Collapsing
    // the two is what let the old screen show a confident, fabricated list.
    if (controller.loadError.isNotEmpty && controller.devices.isEmpty) {
      return AppEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load devices',
        message: controller.loadError.value,
        layout: EmptyStateLayout.centered,
        actionLabel: 'Try again',
        onAction: controller.loadDevices,
      );
    }

    if (controller.devices.isEmpty) {
      return const AppEmptyState(
        icon: Icons.devices_rounded,
        title: 'No linked devices',
        message: 'Scan the QR code on your computer to link it to your account.',
        layout: EmptyStateLayout.centered,
      );
    }

    return Column(
      children: controller.devices
          .map((device) => _deviceTile(device, isDark))
          .toList(),
    );
  }

  Widget _deviceTile(LinkedDevice device, bool isDark) {
    final subtitleParts = <String>[
      if (device.platform.isNotEmpty) device.platform,
      device.subtitleParts,
    ].where((part) => part.isNotEmpty).join(' • ');

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        border: Border.all(
          color: device.isRevoked
              ? CustomColor.kDangerRed.withValues(alpha: 0.25)
              : isDark
                  ? CustomColor.kDarkSurface2
                  : CustomColor.kLightBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: CustomColor.kPrimaryLight,
            child: Icon(
              _platformIcon(device.platform),
              color: CustomColor.kPrimaryColor,
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  style: AppTextStyles.titleSm.copyWith(
                    color: device.isRevoked
                        ? CustomColor.kTextTertiary
                        : isDark
                            ? CustomColor.kWhite
                            : CustomColor.kTextPrimary,
                    decoration: device.isRevoked ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleParts.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitleParts,
                    style: AppTextStyles.bodySm.copyWith(
                      color: isDark ? CustomColor.kTextTertiary : CustomColor.kTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (device.isRevoked)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      'Signed out',
                      style: AppTextStyles.helper.copyWith(color: CustomColor.kDangerRed),
                    ),
                  ),
              ],
            ),
          ),
          if (!device.isRevoked)
            Row(
              children: [
                IconButton(
                  tooltip: 'Rename device',
                  icon: Icon(Icons.edit_outlined, size: 20.r),
                  onPressed: () => _rename(device),
                ),
                IconButton(
                  tooltip: 'Sign out device',
                  icon: Icon(Icons.logout_rounded,
                      color: CustomColor.kDangerRed, size: 20.r),
                  onPressed: () => _revoke(device),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
