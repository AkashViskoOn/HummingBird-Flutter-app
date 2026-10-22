import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_list.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_message_details.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

/// Horizontal carousel of upcoming scheduled messages shown on the home screen.
///
/// Displays one compact card at a time with swipeable PageView and pagination
/// dots. Replaces the old vertical list-based [UpcomingScheduleSection].
class ScheduleCarouselSection extends StatefulWidget {
  final VoidCallback? onViewAll;
  final VoidCallback? onNewSchedule;

  const ScheduleCarouselSection({
    super.key,
    this.onViewAll,
    this.onNewSchedule,
  });

  @override
  State<ScheduleCarouselSection> createState() =>
      _ScheduleCarouselSectionState();
}

class _ScheduleCarouselSectionState extends State<ScheduleCarouselSection> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BirdController>(builder: (bird) {
      final upcoming = bird.upcomingScheduledMessages();
      return Container(
        margin: EdgeInsets.only(left: 8.w, right: 8.w, top: 4.h),
        decoration: _cardDecoration(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
          child: upcoming.isEmpty
              ? _buildEmptyState(context)
              : _buildCarousel(context, upcoming),
        ),
      );
    });
  }

  // ── Carousel with cards ──────────────────────────────────────────────────

  Widget _buildCarousel(BuildContext context, List<Messages> upcoming) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clamp page index if data shrunk
    if (_currentPage >= upcoming.length && upcoming.isNotEmpty) {
      _currentPage = upcoming.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pageController.jumpToPage(_currentPage);
        }
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(isDark),
        SizedBox(height: 8.h),
        SizedBox(
          height: 72.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: upcoming.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _ScheduleCard(message: upcoming[i]),
          ),
        ),
        if (upcoming.length > 1) ...[
          SizedBox(height: 8.h),
          _buildDots(upcoming.length, isDark),
        ],
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
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
          onTap: widget.onViewAll ?? _openSchedule,
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

  // ── Pagination dots ──────────────────────────────────────────────────────

  Widget _buildDots(int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: active ? 8.r : 6.r,
          height: active ? 8.r : 6.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? CustomColor.kPrimaryColor
                : (isDark
                    ? CustomColor.kTextOnDarkMuted.withValues(alpha: 0.35)
                    : CustomColor.kTextTertiary.withValues(alpha: 0.35)),
          ),
        );
      }),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildScheduleIcon(),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Nothing scheduled yet',
                    style: (isDark
                            ? AppTextStyles.titleMdOnDark
                            : AppTextStyles.titleMd)
                        .copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Plan a message for later with Humming Bird',
                    style: AppTextStyles.bodySm.copyWith(
                      color: isDark
                          ? CustomColor.kTextOnDarkMuted
                          : CustomColor.kTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 0.h),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: widget.onNewSchedule ?? widget.onViewAll ?? _openSchedule,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryColor,
                borderRadius: BorderRadius.circular(AppRadius.pill.r),
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded,
                      color: CustomColor.kTextOnDark, size: 16.r),
                  SizedBox(width: 0.w),
                  Flexible(
                    child: Text(
                      'Schedule Message',
                      style: AppTextStyles.label.copyWith(
                        color: CustomColor.kTextOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Schedule icon ─────────────────────────────────────────────────────────

  Widget _buildScheduleIcon() {
    return SizedBox(
      width: 64.r,
      height: 64.r,
      child: Image.asset(
        AppAssets.scheduleIcon,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.schedule_rounded,
          color: CustomColor.kPrimaryColor,
          size: 30.r,
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
      border: Border.all(
        color: isDark
            ? CustomColor.kDarkBorder
            : CustomColor.kPrimaryColor.withValues(alpha: 0.12),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  void _openSchedule() {
    Get.to(() => const ScheduleMessagesList(showHeader: true));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Single schedule card inside the PageView
// ═══════════════════════════════════════════════════════════════════════════════

class _ScheduleCard extends StatelessWidget {
  final Messages message;
  const _ScheduleCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = _formatTime(message);
    final name = _resolveName(message);
    final body = (message.mMessage ?? '').trim();
    final preview = body.isEmpty ? 'Scheduled message' : body;

    return GestureDetector(
      onTap: () =>
          Get.to(() => ScheduledMessageDetailsScreen(message: message)),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kTextOnDark,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          border: Border.all(
            color: isDark
                ? CustomColor.kDarkBorder
                : CustomColor.kLightBorder.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Clock icon
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: CustomColor.kUltraLightPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.schedule_rounded,
                  color: CustomColor.kPrimaryColor, size: 18.r),
            ),
            SizedBox(width: 12.w),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: AppTextStyles.titleSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? CustomColor.kTextOnDark
                          : CustomColor.kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$preview → $name',
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
            SizedBox(width: 8.w),
            // View button
            GestureDetector(
              onTap: () =>
                  Get.to(() => ScheduledMessageDetailsScreen(message: message)),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: CustomColor.kUltraLightPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View',
                      style: AppTextStyles.bodySm.copyWith(
                        color: CustomColor.kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: CustomColor.kPrimaryColor, size: 10.r),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Time formatting (matches existing logic) ─────────────────────────────

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

  // ── Name resolution (matches existing logic) ─────────────────────────────

  String _resolveName(Messages m) {
    if ((m.mReceiver ?? '').isNotEmpty) return m.mReceiver!;
    try {
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
    } catch (_) {}
    return m.mReceiverId ?? 'Chat';
  }
}
