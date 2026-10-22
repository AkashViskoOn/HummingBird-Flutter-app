import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/settings/setting_tile.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/pages/setting/about/licenses_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _appVersion = '1.0.0';
  static const _buildNumber = '2';

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'About'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 32.h),
                    Icon(
                      Icons.chat_bubble_rounded,
                      size: 72.r,
                      color: CustomColor.kPrimaryColor,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Humming Bird',
                      style: AppTextStyles.headingXl
                          .copyWith(color: CustomColor.kTextPrimary),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Version $_appVersion ($_buildNumber)',
                      style: AppTextStyles.subtitle
                          .copyWith(color: CustomColor.kTextSecondary),
                    ),
                    SizedBox(height: 28.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          SettingTile(
                            onTap: () => launchUrl(
                              Uri.parse('https://myhummingbird.net/terms'),
                              mode: LaunchMode.externalApplication,
                            ),
                            color: CustomColor.kPrimaryColor,
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                          ),
                          SizedBox(height: 4.h),
                          SettingTile(
                            onTap: () => launchUrl(
                              Uri.parse('https://myhummingbird.net/privacy'),
                              mode: LaunchMode.externalApplication,
                            ),
                            color: CustomColor.kPrimaryMedium,
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                          ),
                          SizedBox(height: 4.h),
                          SettingTile(
                            onTap: () => Get.to(() => const LicensesPage()),
                            color: CustomColor.kOnlineGreen,
                            icon: Icons.code_rounded,
                            title: 'Open Source Licenses',
                          ),
                          SizedBox(height: 4.h),
                          SettingTile(
                            onTap: () {},
                            color: CustomColor.kGoldAccent,
                            icon: Icons.info_outline,
                            title: 'App Version',
                            subtitle: '$_appVersion ($_buildNumber)',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                    Text(
                      'Made with ❤️',
                      style: AppTextStyles.subtitle
                          .copyWith(color: CustomColor.kTextTertiary),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '© 2026 Humming Bird',
                      style: AppTextStyles.caption
                          .copyWith(color: CustomColor.kTextTertiary),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
