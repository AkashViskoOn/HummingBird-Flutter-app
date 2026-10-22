import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ScheduledDatesList extends StatelessWidget {
  const ScheduledDatesList({super.key});

  /// Dot colour reflects how many schedules sit on that date.
  Color _dotColorFor(int count) {
    if (count <= 3) return CustomColor.kSuccess;
    if (count <= 6) return CustomColor.kGoldAccent;
    if (count <= 9) return CustomColor.kBrandPurple;
    return CustomColor.kPrimaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final BirdController birdController = Get.find();

    return GetBuilder<BirdController>(
      builder: (_) {
        final dates = birdController.scheduledDates;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index].toString();
            final isSelected = birdController.selectedDateIndex.value == index;
            final parsedDate = DateTime.tryParse(date);
            final month =
                parsedDate == null ? '' : DateFormat('MMM').format(parsedDate);
            final day =
                parsedDate == null ? '' : DateFormat('dd').format(parsedDate);
            final weekday =
                parsedDate == null ? '' : DateFormat('EEE').format(parsedDate);
            final messageCount =
                birdController.scheduledMessagesMap[date]?.length ?? 0;
            final dotColor = _dotColorFor(messageCount);

            return GestureDetector(
              onTap: () {
                birdController.selectDate(date: date);
                birdController.updateIndex(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: 68.w.clamp(58.0, 74.0),
                margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 6.h),
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
                  color: isSelected ? null : CustomColor.kTextOnDark,
                  border: Border.all(
                    color: isSelected
                        ? CustomColor.kPrimaryColor
                        : CustomColor.kLightBorder,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? CustomColor.kPrimaryColor.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: isSelected ? 14 : 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        month,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                            color: isSelected
                                ? CustomColor.kTextOnDark
                                    .withValues(alpha: 0.85)
                                : CustomColor.kTextTertiary),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        day,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingMd.copyWith(
                            color: isSelected
                                ? CustomColor.kTextOnDark
                                : CustomColor.kTextPrimary),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        weekday,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm.copyWith(
                            color: isSelected
                                ? CustomColor.kTextOnDark
                                    .withValues(alpha: 0.85)
                                : CustomColor.kTextTertiary),
                      ),
                      if (messageCount > 0) ...[
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            messageCount.clamp(1, 3),
                            (_) => Container(
                              width: 4.r,
                              height: 4.r,
                              margin: EdgeInsets.symmetric(horizontal: 1.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CustomColor.kTextOnDark
                                    : dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
