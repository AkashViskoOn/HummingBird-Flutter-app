import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/pages/calling/blocked_users_page.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class CallSettingsPage extends StatefulWidget {
  const CallSettingsPage({super.key});

  @override
  State<CallSettingsPage> createState() => _CallSettingsPageState();
}

class _CallSettingsPageState extends State<CallSettingsPage> {
  late bool _vibrationEnabled;
  late bool _noiseCancellation;
  late String _selectedRingtone;

  // Only ringtones that actually ship as assets
  final _ringtones = ['Default', 'Silent'];

  @override
  void initState() {
    super.initState();
    final storage = GetStorage();
    _vibrationEnabled = storage.read('call_settings_vibration') ?? true;
    _noiseCancellation = storage.read('call_settings_noise') ?? true;
    _selectedRingtone =
        (storage.read('call_settings_ringtone') ?? 'default') == 'silent'
            ? 'Silent'
            : 'Default';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Call Settings'),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            const _SectionLabel(text: 'RINGTONE & VIBRATION'),
            SizedBox(height: 8.h),
            _SettingsTile(
              title: 'Ringtone',
              subtitle: _selectedRingtone,
              icon: Icons.ring_volume_rounded,
              onTap: () => _showRingtonePicker(),
            ),
            _SwitchTile(
              title: 'Vibration',
              subtitle: 'Vibrate on incoming calls',
              icon: Icons.vibration_rounded,
              value: _vibrationEnabled,
              onChanged: (v) {
                setState(() => _vibrationEnabled = v);
                GetStorage().write('call_settings_vibration', v);
              },
            ),
            SizedBox(height: 20.h),
            const _SectionLabel(text: 'AUDIO'),
            SizedBox(height: 8.h),
            _SwitchTile(
              title: 'Noise Cancellation',
              subtitle: 'Reduce background noise during calls',
              icon: Icons.hearing_rounded,
              value: _noiseCancellation,
              onChanged: (v) {
                setState(() => _noiseCancellation = v);
                GetStorage().write('call_settings_noise', v);
              },
            ),
            SizedBox(height: 20.h),
            const _SectionLabel(text: 'COMING SOON'),
            SizedBox(height: 8.h),
            _SwitchTile(
              title: 'Call Forwarding',
              subtitle: 'Not available yet',
              icon: Icons.call_missed_outgoing_rounded,
              value: false,
              enabled: false,
              onChanged: (_) {},
            ),
            _SwitchTile(
              title: 'Call Waiting',
              subtitle: 'Not available yet',
              icon: Icons.call_split_rounded,
              value: false,
              enabled: false,
              onChanged: (_) {},
            ),
            _SwitchTile(
              title: 'Auto-Record Calls',
              subtitle: 'Not available yet',
              icon: Icons.fiber_manual_record_rounded,
              value: false,
              enabled: false,
              onChanged: (_) {},
            ),
            SizedBox(height: 20.h),
            const _SectionLabel(text: 'PRIVACY'),
            SizedBox(height: 8.h),
            _SettingsTile(
              title: 'Blocked Users',
              subtitle: 'Manage blocked contacts for chats & calls',
              icon: Icons.block_rounded,
              onTap: () => Get.to(() => const BlockedUsersPage()),
            ),
          ],
        ),
      ),
    );
  }

  void _showRingtonePicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: CustomColor.kDarkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Text(
                'Select Ringtone',
                style: AppTextStyles.headingSm
                    .copyWith(color: CustomColor.kTextOnDark),
              ),
            ),
            const Divider(color: CustomColor.kOverlay12, height: 1),
            ..._ringtones.map((r) => ListTile(
                  title: Text(
                    r,
                    style: GoogleFonts.poppins(color: CustomColor.kTextOnDark),
                  ),
                  trailing: _selectedRingtone == r
                      ? const Icon(Icons.check,
                          color: CustomColor.kPrimaryColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedRingtone = r);
                    GetStorage().write('call_settings_ringtone',
                        r == 'Silent' ? 'silent' : 'default');
                    Get.back();
                  },
                )),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.caption
          .copyWith(color: CustomColor.kTextTertiary, letterSpacing: 1),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Material(
        color: CustomColor.kCardBackground,
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child:
                      Icon(icon, color: CustomColor.kPrimaryColor, size: 20.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.titleSm
                              .copyWith(color: CustomColor.kTextPrimary)),
                      if (subtitle.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(subtitle,
                            style: AppTextStyles.bodySm
                                .copyWith(color: CustomColor.kTextTertiary)),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: CustomColor.kTextTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: CustomColor.kCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
              ),
              child: Icon(icon,
                  color: enabled
                      ? CustomColor.kPrimaryColor
                      : CustomColor.kTextTertiary,
                  size: 20.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.titleSm.copyWith(
                          color: enabled
                              ? CustomColor.kTextPrimary
                              : CustomColor.kTextTertiary)),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(subtitle,
                        style: AppTextStyles.bodySm
                            .copyWith(color: CustomColor.kTextTertiary)),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: CustomColor.kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
