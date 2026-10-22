import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/settings/clean_tiles.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/settings_controller.dart';
import 'package:humming_bird/pages/profile/profile_view.dart';
import 'package:humming_bird/pages/setting/account/change_number.dart';
import 'package:humming_bird/pages/setting/account/delete_account.dart';
import 'package:humming_bird/pages/setting/account/req_account_info.dart';
import 'package:humming_bird/pages/setting/account/subscription_packages.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AppSettingsController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      appBar: CommonAppBar(title: 'Account'),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          const CleanSectionLabel(text: 'Account Settings'),
          SizedBox(height: 6.h),
          CleanSettingsTile(
            onTap: () => Get.to(() => const UserProfileScreen()),
            icon: Icons.person_outline,
            title: 'Profile Settings',
            subtitle: 'View and edit your profile',
          ),
          CleanSettingsTile(
            onTap: () => Get.to(() => const ChangeNumber()),
            icon: Icons.contact_page_outlined,
            title: 'Change Number',
            subtitle: 'Move your account to a new number',
          ),
          CleanSettingsTile(
            onTap: () => Get.to(() => const ReqAccountInfo()),
            icon: Icons.info_outline,
            title: 'Request Account Info',
            subtitle: 'Get a report of your account data',
          ),
          CleanSettingsTile(
            onTap: () => Get.to(() => const SubscriptionPackagesPage()),
            icon: Icons.workspace_premium_outlined,
            title: 'Premium Packages',
            subtitle: 'Unlock premium features',
          ),
          SizedBox(height: 16.h),
          const CleanSectionLabel(text: 'Danger Zone'),
          SizedBox(height: 6.h),
          CleanSettingsTile(
            onTap: () => Get.to(() => const DeleteAccount()),
            icon: Icons.delete_outline,
            title: 'Delete My Account',
            subtitle: 'Permanently delete your account',
            danger: true,
          ),
        ],
      ),
    );
  }
}
