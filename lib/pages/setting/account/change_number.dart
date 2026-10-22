import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/settings/clean_tiles.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/settings_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ChangeNumber extends StatefulWidget {
  const ChangeNumber({super.key});

  @override
  State<ChangeNumber> createState() => _ChangeNumberState();
}

class _ChangeNumberState extends State<ChangeNumber> {
  late AppSettingsController settingsController;

  @override
  void initState() {
    super.initState();
    settingsController = Get.find();
    // Pre-fill the current number so the user only has to type the new one.
    // The stored number is the 10-digit national format (no country code),
    // which matches what IntlPhoneField expects for the IN dial code.
    final current = Get.find<UserController>().user?.userMobileNum ?? '';
    settingsController.oldNumberController.text = current;
  }

  @override
  void dispose() {
    settingsController.oldNumberController.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Change Number'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r)
            .copyWith(bottom: 16.r + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CleanSectionLabel(text: 'Current Number'),
            SizedBox(height: 6.h),
            CleanCard(
              child: IntlPhoneField(
                controller: settingsController.oldNumberController,
                initialCountryCode: 'IN',
                decoration: InputDecoration(
                  hintText: 'Old phone number',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (phone) {},
              ),
            ),
            SizedBox(height: 16.h),
            const CleanSectionLabel(text: 'New Number'),
            SizedBox(height: 6.h),
            CleanCard(
              child: IntlPhoneField(
                controller: settingsController.newNumberController,
                initialCountryCode: 'IN',
                decoration: InputDecoration(
                  hintText: 'New phone number',
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
                onPressed: () {
                  settingsController.requestChangeNumber();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColor.kPrimaryFill,
                  foregroundColor: CustomColor.kWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  ),
                ),
                child: Text(
                  'Submit',
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
