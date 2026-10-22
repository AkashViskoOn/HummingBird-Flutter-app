import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/reminder_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// "Remind Me" picker for a follow-up reminder on a message: quick slots
/// (later today / tomorrow morning / in 1 day) + a custom date & time picker.
/// Creates a *local* reminder — it never sends a message.
class ReminderOptionsSheet extends StatelessWidget {
  final Messages message;
  final String roomId;
  final String receiverId;
  final String roomUsers;
  final String name;
  final String userNumber;
  final String userProfile;
  final bool isGroup;

  const ReminderOptionsSheet({
    super.key,
    required this.message,
    required this.roomId,
    required this.receiverId,
    required this.roomUsers,
    required this.name,
    required this.userNumber,
    required this.userProfile,
    required this.isGroup,
  });

  static void show(
    BuildContext context, {
    required Messages message,
    required String roomId,
    required String receiverId,
    required String roomUsers,
    required String name,
    required String userNumber,
    required String userProfile,
    required bool isGroup,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      builder: (_) => ReminderOptionsSheet(
        message: message,
        roomId: roomId,
        receiverId: receiverId,
        roomUsers: roomUsers,
        name: name,
        userNumber: userNumber,
        userProfile: userProfile,
        isGroup: isGroup,
      ),
    );
  }

  DateTime _laterToday() {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, 20, 0);
    return target.isAfter(now) ? target : now.add(const Duration(hours: 2));
  }

  DateTime _tomorrowMorning() =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
          .add(const Duration(days: 1, hours: 9));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
    final secondaryText =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                decoration: BoxDecoration(
                  color: secondaryText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 2.h),
                child: Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        gradient: CustomColor.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      ),
                      child: Icon(Icons.alarm_rounded,
                          color: CustomColor.kTextOnDark, size: 20.r),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Remind Me',
                      style: AppTextStyles.titleMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Get a local reminder for this message — nothing is sent.',
                    style: AppTextStyles.bodySm.copyWith(color: secondaryText),
                  ),
                ),
              ),
              SizedBox(height: 6.h),
              _option(
                context,
                icon: Icons.nights_stay_rounded,
                title: 'Later Today',
                subtitle: 'Tonight at 8:00 PM',
                onTap: () => _create(context, _laterToday()),
              ),
              _option(
                context,
                icon: Icons.wb_twilight_rounded,
                title: 'Tomorrow Morning',
                subtitle: 'Tomorrow at 9:00 AM',
                onTap: () => _create(context, _tomorrowMorning()),
              ),
              _option(
                context,
                icon: Icons.event_repeat_rounded,
                title: 'In 1 Day',
                subtitle: 'Around this time, tomorrow',
                onTap: () => _create(
                    context, DateTime.now().add(const Duration(days: 1))),
              ),
              _option(
                context,
                icon: Icons.more_time_rounded,
                title: 'Custom Date & Time',
                subtitle: 'Pick your own reminder time',
                onTap: () => _pickCustom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final secondaryText =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;

    return ListTile(
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
        child: Icon(icon, color: CustomColor.kPrimaryColor, size: 20.r),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMd.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySm.copyWith(color: secondaryText),
      ),
      trailing:
          Icon(Icons.chevron_right_rounded, color: secondaryText, size: 20.r),
      onTap: onTap,
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !context.mounted) return;
    final remindAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (remindAt.isBefore(DateTime.now())) {
      Utils.showGetSnackBar('Please pick a future time');
      return;
    }
    _create(context, remindAt);
  }

  void _create(BuildContext context, DateTime remindAt) {
    Navigator.pop(context);
    Get.find<ReminderController>().createReminder(
      messageId: message.mId ?? '',
      messageText: message.mMessage ?? '',
      roomId: roomId,
      receiverId: receiverId,
      roomUsers: roomUsers,
      name: name,
      userNumber: userNumber,
      userProfile: userProfile,
      isGroup: isGroup,
      remindAt: remindAt,
    );
  }
}
