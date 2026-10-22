import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/pages/Schedule_Pages/scheduled_messages_page.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Shown right after a message gets scheduled from the chat composer —
/// confirms the schedule with a success state, preview, repeat/start/end,
/// audience and quick navigation to the Schedule tab.
class ScheduleConfirmationSheet extends StatelessWidget {
  final Messages message;

  const ScheduleConfirmationSheet({super.key, required this.message});

  String _intervalLabel() {
    switch (message.interval) {
      case '1':
        return 'Daily';
      case '2':
        return 'Weekly';
      case '3':
        return 'Monthly';
      case '4':
        return 'Yearly';
      default:
        return 'Once';
    }
  }

  String _endCondition() {
    if (message.interval == null || message.interval == '0') return 'Once';
    if (message.count == '-1' || message.count == '0') return 'Forever';
    return 'After ${message.count} occurrences';
  }

  String _audience() {
    final receiverId = message.mReceiverId?.trim() ?? '';
    if (receiverId.isEmpty) return 'Group chat';
    final name =
        Get.find<ContactController>().getUserNameById(receiverId).trim();
    return name.isEmpty ? 'Unknown contact' : name;
  }

  String _preview() {
    if (message.mMessageType != '0') {
      return AppHelper.getMediaName(fileType: message.mMessageType ?? '');
    }
    final text = message.mMessage?.trim() ?? '';
    return text.isEmpty ? '(empty message)' : text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? CustomColor.kDarkSurface : CustomColor.kWhite;
    final surface2 =
        isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
    final border = isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
    final text1 = isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final text3 =
        isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kSuccess.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CustomColor.kSuccess.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CustomColor.kSuccess.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 40.r,
                    color: CustomColor.kSuccess,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Message Scheduled!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLg.copyWith(color: text1),
              ),
              SizedBox(height: 4.h),
              Text(
                'Your message will be sent automatically at the scheduled time.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(color: text3),
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: surface2,
                  borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _preview(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMd.copyWith(color: text1),
                    ),
                    SizedBox(height: 14.h),
                    _infoRow(
                      Icons.event_repeat_rounded,
                      'Repeat',
                      _intervalLabel(),
                      isDark,
                    ),
                    _infoRow(
                      Icons.schedule_rounded,
                      'Start',
                      AppHelper.formatDateTimeFromEpoch(
                        message.mScheduledAt ?? '0',
                        'EEE, MMM d, yyyy · h:mm a',
                      ),
                      isDark,
                    ),
                    _infoRow(
                      Icons.flag_rounded,
                      'End',
                      _endCondition(),
                      isDark,
                    ),
                    _infoRow(
                      Icons.person_rounded,
                      'Audience',
                      _audience(),
                      isDark,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              AppButton(
                text: 'View Scheduled Messages',
                onTap: () {
                  Get.back();
                  Get.to(() => const ScheduledMessagesPage());
                },
                backgroundColor: CustomColor.kPrimaryFill,
              ),
              SizedBox(height: 10.h),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Close',
                  style: AppTextStyles.titleSm.copyWith(color: text3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    final labelColor =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
    final valueColor =
        isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: CustomColor.kPrimaryColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(color: labelColor),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySm.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
