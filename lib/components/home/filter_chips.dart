import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ChatFilterChips extends StatelessWidget {
  final RxString selectedFilter;
  final RxInt unreadCount;
  final VoidCallback? onMoreTap;

  const ChatFilterChips({
    super.key,
    required this.selectedFilter,
    required this.unreadCount,
    this.onMoreTap,
  });

  static const _filters = [
    _FilterData('All Chats', null, false),
    _FilterData('Unread', null, false),
    // _FilterData('Mentions', Icons.alternate_email_rounded, false),
    // _FilterData('Pinned', Icons.push_pin_rounded, false),
    // _FilterData('Archived', Icons.archive_rounded, false),
    // _FilterData('Unseen', Icons.visibility_off_rounded, true),
    // _FilterData('Favorites', Icons.star_rounded, false),
    _FilterData('Groups', Icons.groups_rounded, false),
    _FilterData('More', Icons.more_horiz_rounded, false),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      // height: 25.h,
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final filter = _filters[index];

          return Obx(() {
            final isSelected = selectedFilter.value == filter.label;
            final isDisabled = filter.isDisabled;

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : filter.label == 'More'
                      ? onMoreTap
                      : () => selectedFilter.value = filter.label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? (isDark
                          ? CustomColor.kDarkSurface3
                          : CustomColor.kLightBg)
                      : isSelected
                          ? CustomColor.kPrimaryLight
                          : (isDark
                              ? CustomColor.kDarkSurface2
                              : CustomColor.kTextOnDark),
                  borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                  border: Border.all(
                    color: isDisabled
                        ? (isDark
                            ? CustomColor.kDarkBorder
                            : CustomColor.kLightBorder)
                        : isSelected
                            ? CustomColor.kPrimaryColor
                            : (isDark
                                ? CustomColor.kDarkBorder
                                : CustomColor.kLightBorder),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter.icon != null) ...[
                      Icon(
                        filter.icon,
                        size: 14.r,
                        color: isDisabled
                            ? CustomColor.kTextTertiary
                            : isSelected
                                ? CustomColor.kTextPrimary
                                : CustomColor.kTextSecondary,
                      ),
                      SizedBox(width: 6.w),
                    ],
                    Text(
                      filter.label,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isDisabled
                            ? CustomColor.kTextTertiary
                            : isSelected
                                ? CustomColor.kTextPrimary
                                : (isDark
                                    ? CustomColor.kTextOnDarkSecondary
                                    : CustomColor.kTextSecondary),
                      ),
                    ),
                    if (filter.label == 'Unread') ...[
                      SizedBox(width: 6.w),
                      Obx(() {
                        final count = unreadCount.value;
                        if (count <= 0) return const SizedBox.shrink();
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: CustomColor.kDangerRed,
                            borderRadius:
                                BorderRadius.circular(AppRadius.xxxl.r),
                          ),
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: CustomColor.kTextOnDark,
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }
}

class _FilterData {
  final String label;
  final IconData? icon;
  final bool isDisabled;

  const _FilterData(this.label, this.icon, this.isDisabled);
}
