import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';

class MessageInfoSheet extends StatelessWidget {
  final String messageId;

  const MessageInfoSheet({super.key, required this.messageId});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final msg =
        chatController.messages.firstWhereOrNull((m) => m.mId == messageId);

    if (msg == null) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.section.r),
        child: Text('Message not found'),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      padding: EdgeInsets.all(AppSpacing.xxxl.r),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      child: Entrance(
          duration: const Duration(milliseconds: 280),
          slideOffset: const Offset(0, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSpacing.xpage.w,
                  height: AppSpacing.xs.h,
                  decoration: BoxDecoration(
                    color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxl.h),
              Text(
                'Message Info',
                style: AppTextStyles.headingMd,
              ),
              SizedBox(height: AppSpacing.xxxl.h),
              if (msg.isScheduledMessage) ...[
                _infoRow('Status', _getScheduleStatusText(msg.mStatus)),
                _infoRow(
                  'Scheduled',
                  AppHelper.formatDateTimeFromEpoch(
                    msg.mScheduledAt ?? '0',
                    'MMM d, yyyy h:mm a',
                  ),
                ),
                _infoRow('Repeat', _getIntervalLabel(msg.interval)),
                _infoRow('Audience', _getAudienceText(msg)),
                _infoRow('Created on', _formatTime(msg.mCreatedAt)),
                Divider(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.2),
                  height: AppSpacing.xxl.h,
                ),
              ],
              _infoRow('Status', _getStatusText(msg.mReadStatus)),
              _infoRow('Sent', _formatTime(msg.mCreatedAt)),
              if (msg.mReadStatus == '2' || msg.mReadStatus == '3')
                _infoRow('Delivered', _formatTime(msg.mCreatedAt)),
              if (msg.mReadStatus == '3')
                _infoRow('Seen', _formatTime(msg.mUpdatedAt)),
              if (msg.mIsEdited == '1')
                _infoRow('Edited', _formatTime(msg.mUpdatedAt)),
              if ((msg.mSeenBy ?? '').isNotEmpty && msg.mSeenBy != '[]')
                _infoRow('Seen by', _getSeenByText(msg.mSeenBy!)),
            ],
          )),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xl.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMd
                .copyWith(color: CustomColor.kTextSecondary),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case '0':
        return 'Pending';
      case '1':
        return 'Sent';
      case '2':
        return 'Delivered';
      case '3':
        return 'Seen';
      default:
        return 'Unknown';
    }
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '—';
    try {
      final dt = DateTime.parse(time);
      return DateFormat('MMM d, yyyy h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }

  String _getSeenByText(String seenBy) {
    try {
      final list = jsonDecode(seenBy) as List<dynamic>? ?? [];
      final ids = list.cast<String>();
      return ids.isEmpty
          ? '—'
          : '${ids.length} ${ids.length == 1 ? 'person' : 'people'}';
    } catch (_) {
      return '—';
    }
  }

  String _getScheduleStatusText(String? status) {
    switch (status?.toString()) {
      case 'sent':
        return 'Sent';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  String _getIntervalLabel(String? interval) {
    switch (interval) {
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

  String _getAudienceText(Messages msg) {
    final receiverId = msg.mReceiverId?.trim() ?? '';
    if (receiverId.isEmpty) return 'Group chat';
    try {
      final name =
          Get.find<ContactController>().getUserNameById(receiverId).trim();
      return name.isEmpty ? 'Unknown contact' : name;
    } catch (_) {
      return 'Unknown contact';
    }
  }
}
