import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:humming_bird/components/Aavatar/user-avatar.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

// ignore: non_constant_identifier_names
ListView UserScheduleList(context) {
  return ListView(
    padding: EdgeInsets.only(top: 20.h),
    children: [
      InkWell(
        onTap: () {},
        child: Container(
          padding: EdgeInsets.all(12.r),
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: CustomColor.kTextOnDark,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Slidable(
            startActionPane:
                ActionPane(motion: const StretchMotion(), children: [
              SizedBox(width: 4.w),
              SlidableAction(
                borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
                onPressed: ((context) {}),
                icon: Icons.phone,
                backgroundColor: Colors.blue,
              ),
              SizedBox(width: 4.w),
              SlidableAction(
                borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
                onPressed: ((context) {}),
                icon: Icons.archive,
                backgroundColor: Colors.green,
              ),
            ]),
            endActionPane: ActionPane(motion: const StretchMotion(), children: [
              SizedBox(width: 4.w),
              SlidableAction(
                flex: 1,
                borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
                onPressed: ((context) {}),
                icon: Icons.block,
                foregroundColor: CustomColor.kTextOnDark,
                backgroundColor: Colors.black,
              ),
              SizedBox(width: 4.w),
              SlidableAction(
                borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
                onPressed: ((context) {}),
                icon: Icons.delete,
                foregroundColor: CustomColor.kTextOnDark,
                backgroundColor: Colors.red,
              ),
            ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const UserAvatarList(
                        filename: 'user8.jpg',
                        name: 'Mr.Harry',
                        radius: 20,
                      ),
                      SizedBox(width: 12.w),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mr.Harry',
                              style: AppTextStyles.titleMd
                                  .copyWith(color: CustomColor.kTextPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "Happy Birth Day...",
                              style: AppTextStyles.subtitle
                                  .copyWith(color: CustomColor.kTextSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10.w, top: 5.h),
                  child: Column(
                    children: [
                      Text(
                        '16:35',
                        style: AppTextStyles.caption
                            .copyWith(color: CustomColor.kTextSecondary),
                      ),
                      SizedBox(height: 5.h),
                      CircleAvatar(
                        radius: 10.r,
                        backgroundColor: CustomColor.kPrimaryFill,
                        child: Text(
                          '2',
                          style: AppTextStyles.labelSm
                              .copyWith(color: CustomColor.kTextOnDark),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        gradient: CustomColor.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                        boxShadow: [
                          BoxShadow(
                            color: CustomColor.kPrimaryColor
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: MaterialButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: Icon(
                          Icons.schedule_send_outlined,
                          color: CustomColor.kTextOnDark,
                          size: 20.r,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
