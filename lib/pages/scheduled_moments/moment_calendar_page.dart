import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/scheduled_moments/moment_card.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/controllers/scheduled_moment_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class MomentCalendarPage extends StatefulWidget {
  const MomentCalendarPage({super.key});

  @override
  State<MomentCalendarPage> createState() => _MomentCalendarPageState();
}

class _MomentCalendarPageState extends State<MomentCalendarPage> {
  final ScheduledMomentController _controller = Get.find();
  late DateTime _visibleMonth;
  DateTime? _selectedDay;
  Map<String, List<ScheduledMoment>> _calendarMap = {};

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime.now();
    _selectedDay = DateTime.now();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    final data = await _controller.fetchCalendar();
    if (data != null && mounted) {
      setState(() => _calendarMap = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;

    return Scaffold(
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      appBar: CommonAppBar(title: 'Moment Calendar'),
      body: Column(
        children: [
          _buildMonthHeader(isDark),
          _buildWeekdayHeaders(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.r, 16.r, 16.r,
                  16.r + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendarGrid(daysInMonth, firstWeekday, isDark),
                  if (_selectedDay != null) ...[
                    SizedBox(height: 16.h),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDay!),
                      style: AppTextStyles.headingSm.copyWith(
                          color: isDark
                              ? CustomColor.kTextOnDark
                              : CustomColor.kTextPrimary),
                    ),
                    SizedBox(height: 8.h),
                    _buildDayMoments(isDark),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Previous month',
            icon: Icon(Icons.chevron_left_rounded,
                color: CustomColor.kPrimaryColor),
            onPressed: () => setState(() {
              _visibleMonth =
                  DateTime(_visibleMonth.year, _visibleMonth.month - 1);
            }),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_visibleMonth),
            style: AppTextStyles.headingSm.copyWith(
                color: isDark
                    ? CustomColor.kTextOnDark
                    : CustomColor.kTextPrimary),
          ),
          IconButton(
            tooltip: 'Next month',
            icon: Icon(Icons.chevron_right_rounded,
                color: CustomColor.kPrimaryColor),
            onPressed: () => setState(() {
              _visibleMonth =
                  DateTime(_visibleMonth.year, _visibleMonth.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders(bool isDark) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: weekdays
            .map((d) => Expanded(
                  child: Center(
                    child: Text(d,
                        style: AppTextStyles.caption
                            .copyWith(color: CustomColor.kTextTertiary)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(int daysInMonth, int firstWeekday, bool isDark) {
    final cells = <Widget>[];
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = DateFormat('yyyy-MM-dd')
          .format(DateTime(_visibleMonth.year, _visibleMonth.month, day));
      final hasMoment = _calendarMap.containsKey(dateStr);
      final isSelected = _selectedDay != null &&
          _selectedDay!.day == day &&
          _selectedDay!.month == _visibleMonth.month &&
          _selectedDay!.year == _visibleMonth.year;
      final isToday = DateTime.now().day == day &&
          DateTime.now().month == _visibleMonth.month &&
          DateTime.now().year == _visibleMonth.year;

      cells.add(
        GestureDetector(
          onTap: () => setState(() {
            _selectedDay =
                DateTime(_visibleMonth.year, _visibleMonth.month, day);
          }),
          child: Container(
            margin: EdgeInsets.all(2.r),
            decoration: BoxDecoration(
              color: isSelected
                  ? CustomColor.kPrimaryColor
                  : isToday
                      ? CustomColor.kPrimaryColor.withValues(alpha: 0.1)
                      : null,
              borderRadius: BorderRadius.circular(AppRadius.lg.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  day.toString(),
                  style: AppTextStyles.label.copyWith(
                      color: isSelected
                          ? CustomColor.kTextOnDark
                          : isDark
                              ? CustomColor.kTextOnDark
                              : CustomColor.kTextPrimary),
                ),
                if (hasMoment)
                  Container(
                    width: 5.r,
                    height: 5.r,
                    decoration: BoxDecoration(
                      color: CustomColor.kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: cells,
    );
  }

  Widget _buildDayMoments(bool isDark) {
    if (_selectedDay == null) return const SizedBox.shrink();
    final key = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final dayMomentsData = _calendarMap[key];
    if (dayMomentsData == null || dayMomentsData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: AppEmptyState(
          icon: Icons.calendar_today_rounded,
          title: 'No moments on this day',
          message: 'Moments scheduled for this date appear here',
          layout: EmptyStateLayout.inline,
        ),
      );
    }
    return Column(
      children: dayMomentsData.map((moment) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: MomentCard(moment: moment),
        );
      }).toList(),
    );
  }
}
