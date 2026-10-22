import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_list.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';

/// Compact "Upcoming" schedule section shown above the home chat filters.
///
/// Shows the next 1-2 future scheduled messages (soonest first) inside a
/// branded white card, or a compact empty-state card when nothing is
/// scheduled. Purely a scroller-friendly summary — full management remains in
/// the dedicated Schedule screen.
class UpcomingScheduleSection extends StatelessWidget {
  /// Called when "View All" is tapped. When null, opens the Schedule list
  /// screen directly.
  final VoidCallback? onViewAll;

  const UpcomingScheduleSection({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BirdController>(builder: (bird) {
      final upcoming = bird.upcomingScheduledMessages();
      final preview = upcoming.take(2).toList();
      return Container(
        margin: EdgeInsets.only(left: 8.w, right: 8.w, top: 8.h),
        decoration: _cardDecoration(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 12.h),
          child: preview.isEmpty
              ? AppEmptyState(
                  icon: Icons.calendar_today_rounded,
                  title: 'Nothing scheduled yet',
                  message: 'Plan a message for later with Humming Bird',
                  layout: EmptyStateLayout.inline,
                  actionLabel: 'Schedule Message',
                  onAction: _openSchedule,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(onViewAll),
                    SizedBox(height: 4.h),
                    ...preview.map((m) => _scheduleRow(message: m)),
                  ],
                ),
        ),
      );
    });
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      borderRadius: BorderRadius.circular(AppRadius.lg.r),
      border: Border.all(
        color: isDark
            ? CustomColor.kDarkBorder
            : CustomColor.kPrimaryColor.withValues(alpha: 0.16),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _header(VoidCallback? onViewAll) {
    final isDark = Get.isDarkMode;
    return Row(
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            gradient: CustomColor.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md.r),
          ),
          child: Icon(Icons.schedule_rounded,
              color: CustomColor.kTextOnDark, size: 16.r),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            'Upcoming',
            style:
                (isDark ? AppTextStyles.titleMdOnDark : AppTextStyles.titleMd)
                    .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        GestureDetector(
          onTap: onViewAll ?? _openSchedule,
          child: Row(
            children: [
              Text(
                'View All',
                style: AppTextStyles.bodySm.copyWith(
                  color: CustomColor.kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 16.r, color: CustomColor.kPrimaryColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scheduleRow({required Messages message}) {
    final isDark = Get.isDarkMode;
    final time = _formatTime(message);
    final name = _resolveName(message);
    final body = (message.mMessage ?? '').trim();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Icon(Icons.access_time_rounded,
                size: 13.r, color: CustomColor.kPrimaryColor),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: CustomColor.kPrimaryColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Send\u201c${body.isEmpty ? 'Scheduled message' : body}\u201d\u2192 $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDarkMuted
                        : CustomColor.kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSchedule() {
    Get.to(() => const ScheduleMessagesList(showHeader: true));
  }

  String _formatTime(Messages m) {
    final at = int.tryParse(m.mScheduledAt ?? '');
    if (at == null || at <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(at * 1000);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;
    final time = DateFormat('h:mm a').format(date);
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Tomorrow, $time';
    return DateFormat('MMM d, h:mm a').format(date);
  }

  String _resolveName(Messages m) {
    if ((m.mReceiver ?? '').isNotEmpty) return m.mReceiver!;
    final homeController = Get.find<HomeController>();
    final roomId = m.mRoomId ?? '';
    Rooms? room;
    for (final r in homeController.singleChatsList) {
      if (r.rId == roomId) {
        room = r;
        break;
      }
    }
    if (room == null) {
      for (final r in homeController.groupsList) {
        if (r.rId == roomId) {
          room = r;
          break;
        }
      }
    }
    if (room != null) {
      final isGroup = (room.rType ?? '0') == '1';
      if (isGroup) return room.rName ?? 'Group';
      return room.rAdminNumber.toString();
    }
    return m.mReceiverId ?? 'Chat';
  }
}
