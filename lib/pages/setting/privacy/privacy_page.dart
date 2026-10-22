import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/settings/clean_tiles.dart';
import 'package:humming_bird/pages/calling/blocked_users_page.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final _box = GetStorage();

  static const _lastSeenKey = 'privacy_last_seen';
  static const _onlineStatusKey = 'privacy_online_status';
  static const _profilePhotoKey = 'privacy_profile_photo';
  static const _aboutKey = 'privacy_about';
  static const _readReceiptsKey = 'privacy_read_receipts';
  static const _groupsKey = 'privacy_groups';
  static const _chatLockKey = 'privacy_chat_lock';
  static const _disappearingKey = 'privacy_disappearing';

  final _selectorOptions = ['Everyone', 'My Contacts', 'Nobody'];
  final _disappearingOptions = ['Off', '24 hours', '7 days', '90 days'];

  bool get _isDarkMode => Get.isDarkMode;

  String _selectorValue(String key, [List<String>? options]) {
    final opts = options ?? _selectorOptions;
    return _box.read<String>(key) ?? opts.first;
  }

  bool _toggleValue(String key) {
    return _box.read<bool>(key) ?? false;
  }

  void _showSelectorSheet(String title, String key, {List<String>? options}) {
    final opts = options ?? _selectorOptions;
    final current = _selectorValue(key, opts);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      backgroundColor:
          _isDarkMode ? CustomColor.kDarkSurface : CustomColor.kWhite,
      builder: (ctx) => SafeArea(
        top: true,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.section.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                child: Text(
                  title,
                  style: AppTextStyles.headingMd.copyWith(
                      color: _isDarkMode
                          ? CustomColor.kTextOnDark
                          : CustomColor.kTextPrimary),
                ),
              ),
              ...opts.map(
                (opt) => ListTile(
                  title: Text(
                    opt,
                    style: AppTextStyles.headingSm.copyWith(
                        color: _isDarkMode
                            ? CustomColor.kTextOnDarkSecondary
                            : CustomColor.kTextPrimary),
                  ),
                  trailing: current == opt
                      ? Icon(Icons.check,
                          color: CustomColor.kPrimaryColor, size: 22.r)
                      : null,
                  onTap: () {
                    _box.write(key, opt);
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisappearingSheet() {
    _showSelectorSheet(
      'Disappearing Messages',
      _disappearingKey,
      options: _disappearingOptions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Privacy'),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            const CleanSectionLabel(text: 'Visibility'),
            SizedBox(height: 6.h),
            CleanSettingsTile(
              onTap: () => _showSelectorSheet('Last Seen', _lastSeenKey),
              icon: Icons.visibility_outlined,
              title: 'Last Seen',
              subtitle: _selectorValue(_lastSeenKey),
            ),
            CleanSettingsTile(
              onTap: () =>
                  _showSelectorSheet('Online Status', _onlineStatusKey),
              icon: Icons.circle_outlined,
              title: 'Online Status',
              subtitle: _selectorValue(_onlineStatusKey),
            ),
            CleanSettingsTile(
              onTap: () =>
                  _showSelectorSheet('Profile Photo', _profilePhotoKey),
              icon: Icons.camera_alt_outlined,
              title: 'Profile Photo',
              subtitle: _selectorValue(_profilePhotoKey),
            ),
            CleanSettingsTile(
              onTap: () => _showSelectorSheet('About', _aboutKey),
              icon: Icons.info_outline,
              title: 'About',
              subtitle: _selectorValue(_aboutKey),
            ),
            SizedBox(height: 16.h),
            const CleanSectionLabel(text: 'Privacy'),
            SizedBox(height: 6.h),
            CleanSwitchTile(
              icon: Icons.mark_email_read_outlined,
              title: 'Read Receipts',
              subtitle: _toggleValue(_readReceiptsKey) ? 'On' : 'Off',
              value: _toggleValue(_readReceiptsKey),
              onChanged: (v) {
                _box.write(_readReceiptsKey, v);
                setState(() {});
              },
            ),
            CleanSettingsTile(
              onTap: () =>
                  _showSelectorSheet('Who can add me to groups', _groupsKey),
              icon: Icons.group_add_outlined,
              title: 'Groups',
              subtitle: _selectorValue(_groupsKey),
            ),
            CleanSettingsTile(
              onTap: () => Get.to(() => const BlockedUsersPage()),
              icon: Icons.block_outlined,
              title: 'Blocked Users',
              subtitle: 'Manage blocked contacts',
            ),
            CleanSwitchTile(
              icon: Icons.lock_outline_rounded,
              title: 'Chat Lock',
              subtitle: _toggleValue(_chatLockKey) ? 'On' : 'Off',
              value: _toggleValue(_chatLockKey),
              onChanged: (v) {
                _box.write(_chatLockKey, v);
                setState(() {});
              },
            ),
            CleanSettingsTile(
              onTap: _showDisappearingSheet,
              icon: Icons.timer_outlined,
              title: 'Disappearing Messages',
              subtitle: _selectorValue(_disappearingKey, _disappearingOptions),
            ),
          ],
        ),
      ),
    );
  }
}
