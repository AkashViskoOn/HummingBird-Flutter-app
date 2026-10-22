import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';

class BlockUserDialog extends StatelessWidget {
  final String userId;
  final String userName;
  const BlockUserDialog(
      {super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.find();
    return Dialog(
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: Get.width * 0.8,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xxxl.r)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contactController.checkIfUserIsBlocked(userId)
                      ? ' Unblock $userName'
                      : ' Block $userName',
                  style: AppTextStyles.headingXl,
                ),
                SizedBox(
                  height: Get.height * 0.02,
                ),
                Row(
                  children: [
                    TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.headingSm
                              .copyWith(color: CustomColor.kTextSecondary),
                        )),
                    TextButton(
                        onPressed: () {
                          contactController.checkIfUserIsBlocked(userId)
                              ? contactController.unBlockUser(userId, userName)
                              : contactController.blockUser(userId, userName);
                        },
                        child: Text(
                          'Confirm',
                          style: AppTextStyles.headingSm
                              .copyWith(color: CustomColor.kPrimaryColor),
                        )),
                  ],
                )
              ],
            ),
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.close_rounded,
                color: CustomColor.kTextTertiary,
                size: AppIcons.xxl.r,
              ),
            ),
          )
        ],
      ),
    );
  }
}
