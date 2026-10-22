import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/login_screen/login.dart';
import 'package:humming_bird/pages/media/gallery_page.dart';
import 'package:humming_bird/pages/Schedule_Pages/scheduled_messages_page.dart';
import 'package:humming_bird/pages/ai/ai_chatbot_page.dart';
import 'package:humming_bird/pages/link_device/views/link_device.dart';
import 'package:humming_bird/pages/profile/profile_view.dart';
import 'package:humming_bird/pages/search/smart_search_page.dart';
import 'package:humming_bird/pages/setting/account/account_page.dart';
import 'package:humming_bird/pages/setting/account/subscription_packages.dart';
import 'package:humming_bird/pages/setting/wallpaper/wallpaper_page.dart';
import 'package:humming_bird/pages/setting/chat_customization/chat_customization_page.dart';
import 'package:humming_bird/pages/setting/account/term_and_condition.dart';
import 'package:humming_bird/pages/setting/about/about_page.dart';
import 'package:humming_bird/pages/setting/privacy/privacy_page.dart';
import 'package:humming_bird/pages/setting/notification/notification.dart';
import 'package:humming_bird/pages/setting/storage/storage_page.dart';
import 'package:humming_bird/pages/calling/call_history_page.dart';
import 'package:humming_bird/pages/calling/call_settings_page.dart';
import 'package:humming_bird/pages/calling/favorites_page.dart';
import 'package:humming_bird/pages/calling/blocked_users_page.dart';
import 'package:humming_bird/components/settings/setting_tile.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/constants.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:share_plus/share_plus.dart';

class SidebarDrawerMenu extends StatelessWidget {
  const SidebarDrawerMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Drawer(
      width: Get.width * 0.82,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CustomColor.kDarkSurface, CustomColor.kDarkSurface2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _ProfileHeader(userController: userController),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xxl.w,
                      AppSpacing.md.h, AppSpacing.xxl.w, AppSpacing.xxl.h),
                  children: [
                    const _SectionLabel(text: 'Settings'),
                    SizedBox(height: AppSpacing.xs.h),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.manage_accounts_rounded,
                      color: CustomColor.kPrimaryColor,
                      title: 'Account',
                      subtitle: 'Profile, number and security',
                      onTap: () => Get.to(() => const AccountPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.shield_outlined,
                      color: CustomColor.kPrimaryColor,
                      title: 'Privacy',
                      subtitle: 'Last seen, online status and more',
                      onTap: () => Get.to(() => const PrivacyPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.wallpaper_rounded,
                      color: CustomColor.kPrimaryLight,
                      title: 'Wallpaper',
                      subtitle: 'Chat background settings',
                      onTap: () => Get.to(() => const WallpaperPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.palette_rounded,
                      color: CustomColor.kPrimaryLight,
                      title: 'Chat Customization',
                      subtitle: 'Bubbles, fonts and colors',
                      onTap: () => Get.to(() => const ChatCustomizationPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.notifications_rounded,
                      color: CustomColor.kPrimaryMedium,
                      title: 'Notifications',
                      subtitle: 'Alerts and message reminders',
                      onTap: () => Get.to(() => const NotificationInfo()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.auto_awesome_rounded,
                      color: CustomColor.kPrimaryMedium,
                      title: 'AI Assistant',
                      subtitle: 'Chat with AI helper',
                      onTap: () => Get.to(() => const AiChatbotPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.search_rounded,
                      color: CustomColor.kSuccess,
                      title: 'Smart Search',
                      subtitle: 'AI-powered message search',
                      onTap: () => Get.to(() => const SmartSearchPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.schedule_send_rounded,
                      color: CustomColor.kGoldAccent,
                      title: 'Schedules',
                      subtitle: 'Review scheduled messages',
                      onTap: () => Get.to(() => const ScheduledMessagesPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.qr_code_scanner_rounded,
                      color: CustomColor.kSuccess,
                      title: 'Link Device',
                      subtitle: 'Scan QR code to connect',
                      onTap: () => Get.to(() => const LinkDeviceScreen()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.storage_rounded,
                      color: CustomColor.kPrimaryMedium,
                      title: 'Storage',
                      subtitle: 'Manage app storage and data',
                      onTap: () => Get.to(() => const StoragePage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.info_outline_rounded,
                      color: CustomColor.kPrimaryLight,
                      title: 'About',
                      subtitle: 'App info and licenses',
                      onTap: () => Get.to(() => const AboutPage()),
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    const _SectionLabel(text: 'Media'),
                    SizedBox(height: AppSpacing.xs.h),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.photo_library_rounded,
                      color: CustomColor.kPrimaryMedium,
                      title: 'Gallery',
                      subtitle: 'View all shared media',
                      onTap: () => Get.to(() => const GalleryPage()),
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    const _SectionLabel(text: 'Calls'),
                    SizedBox(height: AppSpacing.xs.h),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.history_rounded,
                      color: CustomColor.kPrimaryMedium,
                      title: 'Call History',
                      subtitle: 'View recent calls',
                      onTap: () => Get.to(() => const CallHistoryPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.star_rounded,
                      color: CustomColor.kGoldAccent,
                      title: 'Favorites',
                      subtitle: 'Favorite contacts for quick calls',
                      onTap: () => Get.to(() => const FavoritesPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.speed_rounded,
                      color: CustomColor.kOnlineGreen,
                      title: 'Speed Dial',
                      subtitle: 'Most frequently called contacts',
                      onTap: () => Get.to(() => const CallHistoryPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.settings_rounded,
                      color: CustomColor.kPrimaryLight,
                      title: 'Call Settings',
                      subtitle: 'Ringtone, blocking and more',
                      onTap: () => Get.to(() => const CallSettingsPage()),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.block_rounded,
                      color: CustomColor.kDangerRed,
                      title: 'Blocked Users',
                      subtitle: 'Manage blocked contacts for calls',
                      onTap: () => Get.to(() => const BlockedUsersPage()),
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    const _SectionLabel(text: 'Premium'),
                    SizedBox(height: AppSpacing.xs.h),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.workspace_premium_rounded,
                      color: CustomColor.kGoldAccent,
                      title: 'Premium Packages',
                      subtitle: 'Unlock advanced features',
                      onTap: () =>
                          Get.to(() => const SubscriptionPackagesPage()),
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    const _SectionLabel(text: 'Support'),
                    SizedBox(height: AppSpacing.xs.h),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.ios_share_rounded,
                      color: CustomColor.kPrimaryMedium,
                      title: 'Share App',
                      subtitle: 'Invite friends to Humming Bird',
                      onTap: () => SharePlus.instance.share(
                        ShareParams(text: Constants.SHARE_TEXT),
                      ),
                    ),
                    SettingTile(
                      isDarkMode: true,
                      icon: Icons.description_rounded,
                      color: CustomColor.kPrimaryLight,
                      title: 'Terms & Help',
                      subtitle: 'Terms and app information',
                      onTap: () => Get.to(() => const TermsConditionPage()),
                    ),
                  ],
                ),
              ),

              // Divider
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxxl.w),
                child: Divider(
                  color: CustomColor.kOverlay8,
                  thickness: 1,
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),

              // Logout
              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.xxl.w, 0, AppSpacing.xxl.w, AppSpacing.xxxl.h),
                child: GestureDetector(
                  onTap: () async {
                    userController.purgeAccountData();
                    Get.offAll(() => const LoginScreen());
                  },
                  child: Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: CustomColor.kDangerRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                      border: Border.all(
                        color: CustomColor.kDangerRed.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: CustomColor.kDangerRed, size: AppIcons.lg.r),
                        SizedBox(width: AppSpacing.md.w),
                        Text(
                          'Logout',
                          style: AppTextStyles.titleMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CustomColor.kDangerRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userController});
  final UserController userController;

  @override
  Widget build(BuildContext context) {
    final user = userController.user;
    final image = user?.userImage ?? '';
    final name = '${user?.userFirstName ?? ''} ${user?.userLastName ?? ''}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    return GestureDetector(
      onTap: () => Get.to(() => const UserProfileScreen()),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(AppSpacing.xxxl.w, AppSpacing.section.h,
            AppSpacing.xxxl.w, AppSpacing.xxxl.h),
        decoration: BoxDecoration(
          color: CustomColor.kOverlay4,
          border: Border(
            bottom: BorderSide(
              color: CustomColor.kOverlay8,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar with gradient ring
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    CustomColor.kPrimaryColor,
                    CustomColor.kPrimaryMedium
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: CircleAvatar(
                radius: 30.r,
                backgroundColor: CustomColor.kDarkSurface,
                backgroundImage: image.isNotEmpty
                    ? CachedNetworkImageProvider(
                        '${Endpoints.mediaBaseUrl}$image')
                    : const AssetImage(AppAssets.defaultProfilePic)
                        as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),
            ),
            SizedBox(width: 14.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Humming Bird User' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLg.copyWith(
                      fontWeight: FontWeight.w700,
                      color: CustomColor.kTextOnDark,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Container(
                        width: 7.r,
                        height: 7.r,
                        decoration: const BoxDecoration(
                          color: CustomColor.kOnlineGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        user?.userMobileNum ?? 'Online',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color:
                              CustomColor.kTextOnDark.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: CustomColor.kTextOnDark.withValues(alpha: 0.4),
              size: AppIcons.xl.r,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xs.w, AppSpacing.sm.h, AppSpacing.xs.w, AppSpacing.xxs.h),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.chatBadge.copyWith(
          color: CustomColor.kOverlay30,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Drawer item removed — now using shared SettingTile (isDarkMode: true)
