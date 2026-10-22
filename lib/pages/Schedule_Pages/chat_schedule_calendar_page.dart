import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class ChatScheduleCalendarPage extends StatefulWidget {
  final String roomId;
  final String title;

  const ChatScheduleCalendarPage({
    super.key,
    required this.roomId,
    required this.title,
  });

  @override
  State<ChatScheduleCalendarPage> createState() =>
      _ChatScheduleCalendarPageState();
}

class _ChatScheduleCalendarPageState extends State<ChatScheduleCalendarPage> {
  final BirdController birdController = Get.find();
  DateTime _visibleMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await birdController.getScheduledMessages();
      final messages = _scheduledMessages;
      if (messages.isEmpty) return;
      final first = messages.first;
      final date = _dateFromMessage(first);
      if (date == null || !mounted) return;
      setState(() {
        _selectedDate = date;
        _visibleMonth = DateTime(date.year, date.month);
      });
    });
  }

  List<Messages> get _scheduledMessages {
    return birdController.scheduledMessagesMap.values
        .expand((messages) => messages)
        .where((message) => message.mRoomId == widget.roomId)
        .toList()
      ..sort((a, b) {
        final aEpoch = int.tryParse(a.mScheduledAt ?? '') ?? 0;
        final bEpoch = int.tryParse(b.mScheduledAt ?? '') ?? 0;
        return aEpoch.compareTo(bEpoch);
      });
  }

  Map<String, List<Messages>> get _messagesByDate {
    final map = <String, List<Messages>>{};
    for (final message in _scheduledMessages) {
      final date = _dateFromMessage(message);
      if (date == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(date);
      map.putIfAbsent(key, () => []).add(message);
    }
    return map;
  }

  DateTime? _dateFromMessage(Messages message) {
    final epoch = int.tryParse(message.mScheduledAt ?? '');
    if (epoch == null || epoch <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark
          ? CustomColor.kDarkBackground
          : CustomColor.kUltraLightPrimary,
      appBar: CommonAppBar(
        title: 'Scheduled',
        subtitle: widget.title,
        backgroundColor: CustomColor.kPrimaryFill,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: CustomColor.kPrimaryColor,
          onRefresh: birdController.getScheduledMessages,
          child: Obx(
            () => birdController.showLoading.value
                ? Center(
                    child: CircularProgressIndicator(
                      color: CustomColor.kPrimaryColor,
                    ),
                  )
                : _scheduledMessages.isEmpty
                    ? AppEmptyState(
                        icon: Icons.event_busy_rounded,
                        title: 'No scheduled messages',
                        message:
                            'There are no pending scheduled messages for .',
                      )
                    : ListView(
                        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w,
                            24.h + MediaQuery.of(context).padding.bottom),
                        children: [
                          _ChatScheduleCalendar(
                            visibleMonth: _visibleMonth,
                            selectedDate: _selectedDate,
                            messagesByDate: _messagesByDate,
                            onPreviousMonth: () => setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month - 1,
                              );
                            }),
                            onNextMonth: () => setState(() {
                              _visibleMonth = DateTime(
                                _visibleMonth.year,
                                _visibleMonth.month + 1,
                              );
                            }),
                            onSelectDate: (date) =>
                                setState(() => _selectedDate = date),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            '${_messagesByDate[_dateKey(_selectedDate)]?.length ?? 0} messages on ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                            style: AppTextStyles.subtitle.copyWith(
                                color: _isDark
                                    ? CustomColor.kTextOnDarkSecondary
                                    : CustomColor.kTextSecondary),
                          ),
                          SizedBox(height: 10.h),
                          ...(_messagesByDate[_dateKey(_selectedDate)] ?? [])
                              .map((message) => _ChatScheduleCard(
                                    message: message,
                                  )),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

class _ChatScheduleCalendar extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final Map<String, List<Messages>> messagesByDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  const _ChatScheduleCalendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.messagesByDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
  });

  String _key(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
    final surface2 =
        isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
    final border = isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
    final text1 = isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final text3 =
        isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.twentyTwo.r),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: onPreviousMonth,
                style: IconButton.styleFrom(
                  backgroundColor: surface2,
                  foregroundColor: CustomColor.kPrimaryColor,
                  fixedSize: Size(34.r, 34.r),
                  minimumSize: Size(34.r, 34.r),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(visibleMonth),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingSm.copyWith(color: text1),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: onNextMonth,
                style: IconButton.styleFrom(
                  backgroundColor: surface2,
                  foregroundColor: CustomColor.kPrimaryColor,
                  fixedSize: Size(34.r, 34.r),
                  minimumSize: Size(34.r, 34.r),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySm.copyWith(color: text3),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 8.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4.h,
              crossAxisSpacing: 4.w,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final date = DateTime(visibleMonth.year, visibleMonth.month, day);
              final key = _key(date);
              final hasMessages = messagesByDate.containsKey(key);
              final isSelected = _key(selectedDate) == key;

              return InkWell(
                onTap: hasMessages ? () => onSelectDate(date) : null,
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              CustomColor.kPrimaryColor,
                              CustomColor.kPrimaryMedium,
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: CustomColor.kPrimaryColor
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: AppTextStyles.subtitle.copyWith(
                            color:
                                isSelected ? CustomColor.kTextOnDark : text1),
                      ),
                      SizedBox(height: 3.h),
                      SizedBox(
                        width: 5.r,
                        height: 5.r,
                        child: hasMessages
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? CustomColor.kGoldAccent
                                      : CustomColor.kPrimaryColor,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatScheduleCard extends StatelessWidget {
  final Messages message;

  const _ChatScheduleCard({required this.message});

  String _preview() {
    if (message.mMessageType == '0') {
      try {
        final decrypted =
            EncryptionHelper().decryptMessage(message.mMessage ?? '');
        return decrypted.trim().isEmpty ? 'Scheduled message' : decrypted;
      } catch (_) {
        return message.mMessage ?? 'Scheduled message';
      }
    }
    return AppHelper.getMediaName(fileType: message.mMessageType ?? '0');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
    final surface2 =
        isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
    final border = isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
    final text1 = isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final text2 =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
    final epoch = int.tryParse(message.mScheduledAt ?? '');
    final scheduledAt = epoch == null
        ? ''
        : DateFormat('h:mm a')
            .format(DateTime.fromMillisecondsSinceEpoch(epoch * 1000));

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: CustomColor.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
              boxShadow: [
                BoxShadow(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.schedule_send_rounded,
              color: CustomColor.kTextOnDark,
              size: 22.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _preview(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.chatBadge.copyWith(color: text1),
                ),
                SizedBox(height: 4.h),
                Text(
                  scheduledAt,
                  style: AppTextStyles.bodySm.copyWith(color: text2),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: surface2,
              borderRadius: BorderRadius.circular(AppRadius.lg.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_rounded,
                    size: 13.r, color: CustomColor.kPrimaryColor),
                SizedBox(width: 4.w),
                Text(
                  scheduledAt,
                  style: AppTextStyles.caption
                      .copyWith(color: CustomColor.kPrimaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
