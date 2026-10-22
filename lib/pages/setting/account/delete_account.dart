import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/settings/clean_tiles.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/settings_controller.dart';
import 'package:humming_bird/pages/setting/account/change_number.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

const _deleteReasons = [
  'Delete your account info, profile photo, and all your schedules',
  'Delete you from all Humming Bird Groups',
  'Delete your message history on this phone and your iCloud account',
  'Delete any channel that you created',
];

class DeleteAccount extends StatelessWidget {
  const DeleteAccount({super.key});

  @override
  Widget build(BuildContext context) {
    AppSettingsController appSettingsController = Get.find();
    return Scaffold(

      appBar: CommonAppBar(title: 'Delete My Account'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r)
            .copyWith(bottom: 16.r + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CleanCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.delete_forever_outlined,
                        color: CustomColor.kDangerRed,
                        size: 24.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Deleting your account will:',
                        style: AppTextStyles.titleMd
                            .copyWith(color: CustomColor.kTextPrimary),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  ..._deleteReasons.map(
                    (reason) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h, left: 8.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.fiber_manual_record_rounded,
                              size: 6.r, color: CustomColor.kDangerRed),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              reason,
                              style: AppTextStyles.subtitle.copyWith(
                                  color: CustomColor.kTextSecondary,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            const CleanSectionLabel(text: 'Confirm Your Number'),
            SizedBox(height: 6.h),
            CleanCard(
              padding: EdgeInsets.fromLTRB(16.r, 8.h, 16.r, 16.h),
              child: IntlPhoneField(
                controller: appSettingsController.deleteAccountController,
                cursorColor: CustomColor.kPrimaryColor,
                initialCountryCode: 'IN',
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (phone) {},
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColor.kDangerFill,
                  foregroundColor: CustomColor.kWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  ),
                ),
                onPressed: () {
                  appSettingsController.requestDeleteAccount();
                },
                child: Text(
                  'Delete My Account',
                  style: AppTextStyles.titleMd,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColor.kPrimaryLight,
                  foregroundColor: CustomColor.kPrimaryDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  ),
                ),
                onPressed: () => Get.to(() => const ChangeNumber()),
                child: Text(
                  'Change Number Instead',
                  style: AppTextStyles.titleMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
