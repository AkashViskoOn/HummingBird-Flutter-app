import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/settings/clean_tiles.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class NotificationInfo extends StatefulWidget {
  const NotificationInfo({super.key});

  @override
  State<NotificationInfo> createState() => _NotificationInfoState();
}

class _NotificationInfoState extends State<NotificationInfo> {
  final GetStorage _box = GetStorage();

  bool _value(String key, [bool def = true]) => _box.read(key) ?? def;
  void _toggle(String key, bool val) {
    _box.write(key, val);
    setState(() {});
  }

  void _resetAll() {
    final keys = [
      'notif_messages_show',
      'notif_messages_reaction',
      'notif_groups_show',
      'notif_groups_reaction',
      'notif_schedule_show',
      'notif_schedule_reaction',
      'notif_in_app',
      'notif_preview',
      'notif_sound',
      'notif_vibration',
    ];
    for (final k in keys) {
      _box.write(k, true);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Notification'),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            const CleanSectionLabel(text: 'Message Notifications'),
            SizedBox(height: 6.h),
            CleanSwitchTile(
              icon: Icons.notifications_none_rounded,
              title: 'Show Notifications',
              value: _value('notif_messages_show'),
              onChanged: (v) => _toggle('notif_messages_show', v),
            ),
            CleanSwitchTile(
              icon: Icons.favorite_border_rounded,
              title: 'Reaction Notifications',
              value: _value('notif_messages_reaction'),
              onChanged: (v) => _toggle('notif_messages_reaction', v),
            ),
            SizedBox(height: 16.h),
            const CleanSectionLabel(text: 'Group Notifications'),
            SizedBox(height: 6.h),
            CleanSwitchTile(
              icon: Icons.groups_outlined,
              title: 'Show Notifications',
              value: _value('notif_groups_show'),
              onChanged: (v) => _toggle('notif_groups_show', v),
            ),
            CleanSwitchTile(
              icon: Icons.favorite_border_rounded,
              title: 'Reaction Notifications',
              value: _value('notif_groups_reaction'),
              onChanged: (v) => _toggle('notif_groups_reaction', v),
            ),
            SizedBox(height: 16.h),
            const CleanSectionLabel(text: 'Schedule Notifications'),
            SizedBox(height: 6.h),
            CleanSwitchTile(
              icon: Icons.schedule_rounded,
              title: 'Show Notifications',
              value: _value('notif_schedule_show'),
              onChanged: (v) => _toggle('notif_schedule_show', v),
            ),
            CleanSwitchTile(
              icon: Icons.favorite_border_rounded,
              title: 'Reaction Notifications',
              value: _value('notif_schedule_reaction'),
              onChanged: (v) => _toggle('notif_schedule_reaction', v),
            ),
            SizedBox(height: 16.h),
            const CleanSectionLabel(text: 'Other'),
            SizedBox(height: 6.h),
            CleanSwitchTile(
              icon: Icons.phone_android_rounded,
              title: 'In-App Notification',
              value: _value('notif_in_app'),
              onChanged: (v) => _toggle('notif_in_app', v),
            ),
            CleanSwitchTile(
              icon: Icons.preview_outlined,
              title: 'Show Preview',
              subtitle: 'Preview message text inside new message notification.',
              value: _value('notif_preview'),
              onChanged: (v) => _toggle('notif_preview', v),
            ),
            CleanSwitchTile(
              icon: Icons.music_note_outlined,
              title: 'Sound',
              value: _value('notif_sound'),
              onChanged: (v) => _toggle('notif_sound', v),
            ),
            CleanSwitchTile(
              icon: Icons.vibration_outlined,
              title: 'Vibration',
              value: _value('notif_vibration'),
              onChanged: (v) => _toggle('notif_vibration', v),
            ),
            SizedBox(height: 20.h),
            CleanSettingsTile(
              icon: Icons.restart_alt_rounded,
              title: 'Reset Notification Settings',
              danger: true,
              onTap: _resetAll,
            ),
            Padding(
              padding: EdgeInsets.only(left: 4.w, top: 6.h),
              child: Text(
                'Reset all notification settings, including custom notification settings for your schedule & chats.',
                style: AppTextStyles.bodySm
                    .copyWith(color: CustomColor.kTextTertiary, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
