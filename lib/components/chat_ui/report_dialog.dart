import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/components/common/common_textfield.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ReportDialog extends StatefulWidget {
  final String userId;
  final String userName;
  const ReportDialog({super.key, required this.userId, required this.userName});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  late ContactController contactController;

  @override
  void initState() {
    contactController = Get.find();
    contactController.reportController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    contactController.reportController.dispose();
    super.dispose();
  }

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
                  'Report ${widget.userName}',
                  style: AppTextStyles.headingLg,
                ),
                SizedBox(
                  height: Get.height * 0.02,
                ),
                Card(
                  surfaceTintColor: CustomColor.kTextOnDark,
                  child: CommonTextField(
                    controller: contactController.reportController,
                    hintText: 'Describe your issue in 150 words...',
                    maxLines: 5,
                    needShadow: true,
                    bgColor: CustomColor.kTextOnDark,
                    maxLength: 150,
                  ),
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
                    SizedBox(
                      width: Get.width * 0.02,
                    ),
                    TextButton(
                        onPressed: () {
                          contactController.reportUser(
                              widget.userId,
                              contactController.reportController.text.trim(),
                              widget.userName);
                        },
                        child: Text(
                          'Report',
                          style: AppTextStyles.headingSm
                              .copyWith(color: CustomColor.kDangerRed),
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
