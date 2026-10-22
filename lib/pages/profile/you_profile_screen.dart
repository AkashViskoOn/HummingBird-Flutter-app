import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/profile/qr_code_bottom_sheet.dart';
import 'package:humming_bird/components/settings/setting_tile.dart';
import 'package:humming_bird/controllers/profile_controller.dart';
import 'package:humming_bird/controllers/settings_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/Schedule_Pages/scheduled_messages_page.dart';
import 'package:humming_bird/pages/ai/ai_chatbot_page.dart';
import 'package:humming_bird/pages/calling/blocked_users_page.dart';
import 'package:humming_bird/pages/calling/call_history_page.dart';
import 'package:humming_bird/pages/calling/call_settings_page.dart';
import 'package:humming_bird/pages/calling/favorites_page.dart';
import 'package:humming_bird/pages/chats/chat_screens/starred_messages_page.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/image_viewer_widget.dart';
import 'package:humming_bird/pages/link_device/views/link_device.dart';
import 'package:humming_bird/pages/login_screen/login.dart';
import 'package:humming_bird/pages/media/gallery_page.dart';
import 'package:humming_bird/pages/profile/profile_edit.dart';
import 'package:humming_bird/pages/search/smart_search_page.dart';
import 'package:humming_bird/pages/setting/about/about_page.dart';
import 'package:humming_bird/pages/setting/connection/connection_info_screen.dart';
import 'package:humming_bird/pages/setting/account/account_page.dart';
import 'package:humming_bird/pages/setting/account/subscription_packages.dart';
import 'package:humming_bird/pages/setting/account/term_and_condition.dart';
import 'package:humming_bird/pages/setting/chat_customization/chat_customization_page.dart';
import 'package:humming_bird/pages/setting/media_compression_settings_page.dart';
import 'package:humming_bird/pages/setting/notification/notification.dart';
import 'package:humming_bird/pages/setting/privacy/privacy_page.dart';
import 'package:humming_bird/pages/setting/storage/storage_page.dart';
import 'package:humming_bird/pages/setting/wallpaper/wallpaper_page.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class YouProfileScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const YouProfileScreen({super.key, this.onMenuTap});
  @override
  State<YouProfileScreen> createState() => _YouProfileScreenState();
}

class _YouProfileScreenState extends State<YouProfileScreen>
    with SingleTickerProviderStateMixin {
  final UserController userController = Get.find();
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();
    Get.put(ProfileController());
    _entrance = AnimationController(
      vsync: this,
      duration: AppAnimation.medium,
    );
    _fade = CurvedAnimation(parent: _entrance, curve: AppAnimation.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entrance,
      curve: AppAnimation.easeOut,
    ));
    _avatarScale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
    );
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? CustomColor.kDarkBackground
          : CustomColor.kBackground,
      child: SafeArea(
        child: GetBuilder<ProfileController>(
          id: 'update-profile',
          builder: (_) => FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxContentWidth =
                      constraints.maxWidth > 720 ? 640.0 : double.infinity;
                  return ListView(
                    padding: EdgeInsets.only(
                      left: 16.w,
                      right: 16.w,
                      top: 4.h,
                      bottom: AppSpacing.xsection.h,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: maxContentWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(),
                              SizedBox(height: AppSpacing.xxl.h),
                              _buildHeroCard(),
                              SizedBox(height: AppSpacing.xxl.h),
                              ..._buildSettingsSections(),
                              SizedBox(height: AppSpacing.xl.h),
                              _buildLogoutButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return SizedBox(
      height: 56.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: widget.onMenuTap == null
                ? const SizedBox.shrink()
                : _HeaderIconButton(
                    icon: Icons.menu_rounded,
                    semanticLabel: 'Menu',
                    onTap: widget.onMenuTap!,
                  ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'You',
              style: AppTextStyles.headingMd.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark
                    ? CustomColor.kTextOnDark
                    : null,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderIconButton(
                  icon: Icons.qr_code_rounded,
                  semanticLabel: 'QR Code',
                  onTap: () {
                    final name = _userDisplayName;
                    ProfileQrCodeSheet.show(context, name: name);
                  },
                ),
                SizedBox(width: 8.w),
                _HeaderIconButton(
                  icon: Icons.edit_rounded,
                  semanticLabel: 'Edit Profile',
                  onTap: () => Get.to(() => const UpdateProfile()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _userDisplayName {
    final user = userController.user;
    return '${user?.userFirstName ?? ''} ${user?.userLastName ?? ''}'
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // ── Hero Profile Card ───────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    final user = userController.user;
    final image = user?.userImage ?? '';
    final bio = user?.userBio ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl.r, AppSpacing.xxl.r, AppSpacing.xl.r, AppSpacing.xl.r),
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
        borderRadius: BorderRadius.circular(AppRadius.rounded.r),
        border: Border.all(
            color: isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (!isDark) AppShadow.cardLight.first,
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _avatarScale,
            child: _buildAvatar(image),
          ),
          SizedBox(height: AppSpacing.xxl.h),
          Text(
            _userDisplayName.isEmpty ? 'Humming Bird User' : _userDisplayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingLg.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? CustomColor.kTextOnDark : null,
            ),
          ),
          SizedBox(height: AppSpacing.xs.h),
          _buildInfoLine(
            icon: Icons.phone_rounded,
            value: user?.userMobileNum,
          ),
          if ((user?.userEmail?.isNotEmpty ?? false)) ...[
            SizedBox(height: AppSpacing.xs.h),
            _buildInfoLine(
              icon: Icons.mail_outline_rounded,
              value: user?.userEmail,
            ),
          ],
          if (bio.isNotEmpty) ...[
            SizedBox(height: AppSpacing.lg.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg.w, vertical: AppSpacing.sm.h),
              decoration: BoxDecoration(
                color: isDark
                    ? CustomColor.kPrimaryColor.withValues(alpha: 0.12)
                    : CustomColor.kUltraLightPrimary,
                borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                border: Border.all(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark
                      ? CustomColor.kTextOnDarkSecondary
                      : CustomColor.kTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xl.h),
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar(String image) {
    return GestureDetector(
      onTap: image.isEmpty
          ? null
          : () => Get.to(
                () => FullScreenImageView(
                  url: '${Endpoints.mediaBaseUrl}$image',
                ),
              ),
      child: Container(
        width: 120.r,
        height: 120.r,
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [CustomColor.kPrimaryColor, CustomColor.kPrimaryMedium],
          ),
        ),
        child: CircleAvatar(
          backgroundColor: CustomColor.kTextOnDark,
          backgroundImage: image.isNotEmpty
              ? CachedNetworkImageProvider('${Endpoints.mediaBaseUrl}$image')
              : const AssetImage(AppAssets.defaultProfilePic) as ImageProvider,
          onBackgroundImageError: (_, __) {},
        ),
      ),
    );
  }

  Widget _buildInfoLine({required IconData icon, String? value}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 26.r,
          height: 26.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.18)
                : CustomColor.kUltraLightPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13.r, color: CustomColor.kPrimaryColor),
        ),
        SizedBox(width: 6.w),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 240.w),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSm.copyWith(
              color: isDark
                  ? CustomColor.kTextOnDarkSecondary
                  : CustomColor.kTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.to(() => const UpdateProfile()),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            gradient: CustomColor.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_rounded,
                  color: CustomColor.kTextOnDark, size: AppIcons.md.r),
              SizedBox(width: AppSpacing.sm.w),
              Text(
                'Edit Profile',
                style: AppTextStyles.buttonSm.copyWith(fontSize: 13.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Settings Sections ───────────────────────────────────────────────────────
  List<Widget> _buildSettingsSections() {
    return [
      _SettingsSection(
        title: 'Account',
        children: [
          _tile(
            icon: Icons.manage_accounts_rounded,
            color: CustomColor.kPrimaryDark,
            title: 'Account Settings',
            subtitle: 'Change number, request info',
            onTap: () => Get.to(() => const AccountPage()),
          ),
          _tile(
            icon: Icons.shield_outlined,
            color: CustomColor.kOnlineGreen,
            title: 'Privacy & Security',
            subtitle: 'Last seen, read receipts',
            onTap: () => Get.to(() => const PrivacyPage()),
          ),
        ],
      ),
      _SettingsSection(
        title: 'Appearance',
        children: [
          GetBuilder<AppSettingsController>(
            builder: (settings) => _tile(
              icon: Icons.contrast_rounded,
              color: CustomColor.kPrimaryMedium,
              title: 'Theme',
              subtitle:
                  settings.themeMode.value == ThemeMode.dark ? 'Dark' : 'Light',
              onTap: _showThemeSheet,
            ),
          ),
        ],
      ),
      _SettingsSection(
        title: 'Chats',
        children: [
          _tile(
            icon: Icons.wallpaper_rounded,
            color: CustomColor.kPrimaryMedium,
            title: 'Wallpaper',
            subtitle: 'Chat background settings',
            onTap: () => Get.to(() => const WallpaperPage()),
          ),
          _tile(
            icon: Icons.palette_rounded,
            color: CustomColor.kPrimaryColor,
            title: 'Chat Customization',
            subtitle: 'Bubbles, fonts and colors',
            onTap: () => Get.to(() => const ChatCustomizationPage()),
          ),
          _tile(
            icon: Icons.hd_rounded,
            color: CustomColor.kGoldAccent,
            title: 'Media Quality',
            subtitle: 'Compression and upload quality',
            onTap: () => Get.to(() => const MediaCompressionSettingsPage()),
          ),
          _tile(
            icon: Icons.photo_library_rounded,
            color: CustomColor.kPrimaryMedium,
            title: 'Gallery',
            subtitle: 'View all shared media',
            onTap: () => Get.to(() => const GalleryPage()),
          ),
        ],
      ),
      _SettingsSection(
        title: 'Notifications',
        children: [
          _tile(
            icon: Icons.notifications_active_outlined,
            color: CustomColor.kGoldAccent,
            title: 'Notifications',
            subtitle: 'Message and call alerts',
            onTap: () => Get.to(() => const NotificationInfo()),
          ),
        ],
      ),
      _SettingsSection(
        title: 'Storage',
        children: [
          _tile(
            icon: Icons.storage_rounded,
            color: CustomColor.kPrimaryMedium,
            title: 'Storage Usage',
            subtitle: 'Manage app storage and data',
            onTap: () => Get.to(() => const StoragePage()),
          ),
        ],
      ),
      _SettingsSection(
        title: 'Calls',
        children: [
          _tile(
            icon: Icons.settings_rounded,
            color: CustomColor.kPrimaryLight,
            title: 'Call Settings',
            subtitle: 'Ringtone and call preferences',
            onTap: () => Get.to(() => const CallSettingsPage()),
          ),
          _tile(
            icon: Icons.history_rounded,
            color: CustomColor.kPrimaryMedium,
            title: 'Call History',
            subtitle: 'View recent calls',
            onTap: () => Get.to(() => const CallHistoryPage()),
          ),
          _tile(
            icon: Icons.star_rounded,
            color: CustomColor.kGoldAccent,
            title: 'Favorites',
            subtitle: 'Favorite contacts for quick calls',
            onTap: () => Get.to(() => const FavoritesPage()),
          ),
        ],
      ),
      _SettingsSection(
        title: 'Advanced',
        children: [
          _tile(
            icon: Icons.qr_code_scanner_rounded,
            color: CustomColor.kOnlineGreen,
            title: 'Linked Device',
            subtitle: 'Scan QR code to connect',
            onTap: () => Get.to(() => const LinkDeviceScreen()),
          ),
          _tile(
            icon: Icons.block_rounded,
            color: CustomColor.kDangerRed,
            title: 'Blocked Users',
            subtitle: 'Manage blocked contacts',
            onTap: () => Get.to(() => const BlockedUsersPage()),
          ),
          _tile(
            icon: Icons.star_border_rounded,
            color: CustomColor.kGoldAccent,
            title: 'Starred Messages',
            subtitle: 'Messages you starred',
            onTap: () => Get.to(() => const StarredMessagesPage()),
          ),
          _tile(
            icon: Icons.schedule_send_rounded,
            color: CustomColor.kGoldAccent,
            title: 'Scheduled Messages',
            subtitle: 'Review scheduled messages',
            onTap: () => Get.to(() => const ScheduledMessagesPage()),
          ),
          _tile(
            icon: Icons.auto_awesome_rounded,
            color: CustomColor.kPrimaryMedium,
            title: 'AI Assistant',
            subtitle: 'Chat with AI helper',
            onTap: () => Get.to(() => const AiChatbotPage()),
          ),
          _tile(
            icon: Icons.search_rounded,
            color: CustomColor.kOnlineGreen,
            title: 'Smart Search',
            subtitle: 'AI-powered message search',
            onTap: () => Get.to(() => const SmartSearchPage()),
          ),
        ],
      ),
      _SettingsSection(
        title: 'Support',
        children: [
          _tile(
            icon: Icons.wifi_rounded,
            color: CustomColor.kPrimaryMedium,
            title: 'Connection Info',
            subtitle: 'Network, socket & notification status',
            onTap: () => Get.to(() => const ConnectionInfoScreen()),
          ),
          _tile(
            icon: Icons.info_outline_rounded,
            color: CustomColor.kPrimaryLight,
            title: 'About App',
            subtitle: 'App info and licenses',
            onTap: () => Get.to(() => const AboutPage()),
          ),
          _tile(
            icon: Icons.description_rounded,
            color: CustomColor.kPrimaryMedium,
            title: 'Terms & Help',
            subtitle: 'Terms and app information',
            onTap: () => Get.to(() => const TermsConditionPage()),
          ),
          _tile(
            icon: Icons.workspace_premium_rounded,
            color: CustomColor.kGoldAccent,
            title: 'Premium Packages',
            subtitle: 'Unlock advanced features',
            onTap: () => Get.to(() => const SubscriptionPackagesPage()),
          ),
        ],
      ),
    ];
  }

  Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SettingTile(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      isDarkMode: Theme.of(context).brightness == Brightness.dark,
      onTap: onTap,
    );
  }

  // ── Theme selector ──────────────────────────────────────────────────────────
  void _showThemeSheet() {
    final settings = Get.find<AppSettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl.r),
        ),
      ),
      backgroundColor: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
      builder: (ctx) => SafeArea(
        top: true,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.section.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                child: Text(
                  'Theme',
                  style: AppTextStyles.headingMd.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary,
                  ),
                ),
              ),
              _themeOption(
                ctx,
                settings,
                isDark: isDark,
                title: 'Light',
                icon: Icons.light_mode_rounded,
                mode: ThemeMode.light,
              ),
              _themeOption(
                ctx,
                settings,
                isDark: isDark,
                title: 'Dark',
                icon: Icons.dark_mode_rounded,
                mode: ThemeMode.dark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeOption(
    BuildContext ctx,
    AppSettingsController settings, {
    required bool isDark,
    required String title,
    required IconData icon,
    required ThemeMode mode,
  }) {
    final selected = settings.themeMode.value == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: selected
            ? CustomColor.kPrimaryColor
            : isDark
                ? CustomColor.kTextOnDarkSecondary
                : CustomColor.kTextSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSm.copyWith(
          color: isDark
              ? CustomColor.kTextOnDarkSecondary
              : CustomColor.kTextPrimary,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded,
              color: CustomColor.kPrimaryColor, size: 22.r)
          : null,
      onTap: () {
        settings.setThemeMode(mode);
        Navigator.pop(ctx);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
      ),
    );
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          userController.purgeAccountData();
          Get.offAll(() => const LoginScreen());
        },
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: CustomColor.kDangerRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.fourteen),
            border: Border.all(
              color: CustomColor.kDangerRed.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded,
                  color: CustomColor.kDangerRed, size: AppIcons.lg),
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
    );
  }
}

// ── Section helper ────────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xs.w,
            AppSpacing.xs.h,
            AppSpacing.xs.w,
            AppSpacing.md.h,
          ),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.labelSm.copyWith(
              color: isDark
                  ? CustomColor.kTextOnDarkMuted
                  : CustomColor.kTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: 4.h),
          children[i],
        ],
        SizedBox(height: AppSpacing.section.h),
      ],
    );
  }
}

// ── Header icon button ────────────────────────────────────────────────────────
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Ink(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kTextOnDark,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: isDark ? const [] : AppShadow.cardLight,
              border: Border.all(
                color:
                    isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
              size: 20.r,
            ),
          ),
        ),
      ),
    );
  }
}
