import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/settings/clean_tiles.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/settings_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class ReqAccountInfo extends StatefulWidget {
  const ReqAccountInfo({super.key});

  @override
  State<ReqAccountInfo> createState() => _ReqAccountInfoState();
}

class _ReqAccountInfoState extends State<ReqAccountInfo> {
  @override
  Widget build(BuildContext context) {
    AppSettingsController settingsController = Get.find();
    return Scaffold(

      appBar: CommonAppBar(title: 'Request Account Info'),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          const CleanSectionLabel(text: 'Account Information'),
          SizedBox(height: 6.h),
          CleanSettingsTile(
            icon: Icons.description_outlined,
            title: 'Request Send',
            subtitle: 'Ready By 25 December',
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Text(
              "Your report will be ready in about 1 day. You'll have a few weeks to download your report after it's available.",
              style: AppTextStyles.bodySm
                  .copyWith(color: CustomColor.kTextTertiary, height: 1.4),
            ),
          ),
          SizedBox(height: 20.h),
          const CleanSectionLabel(text: 'Channels Activity'),
          SizedBox(height: 6.h),
          CleanSettingsTile(
            icon: Icons.campaign_outlined,
            title: 'Request Channels Report',
            subtitle: 'Ready in about 1 day',
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Text(
              "Your report will be ready in about 1 day. You'll have a few weeks to download your report after it's available.",
              style: AppTextStyles.bodySm
                  .copyWith(color: CustomColor.kTextTertiary, height: 1.4),
            ),
          ),
          SizedBox(height: 24.h),
          AppButton(
            text: 'Download Messages',
            onTap: () => settingsController.downloadMessages(),
          ),
        ],
      ),
    );
  }
}
