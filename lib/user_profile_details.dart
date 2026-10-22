import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/chat_ui/block_user_dialog.dart';
import 'package:humming_bird/components/chat_ui/delete_room_dialog.dart';
import 'package:humming_bird/components/chat_ui/report_dialog.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/media/shared_media_strip.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/image_viewer_widget.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_dimensions.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class UserProfileDetails extends StatelessWidget {
  final String userName;
  final String userProfile;
  final String userNumber;
  final String userBio;
  final String roomId;

  const UserProfileDetails({
    super.key,
    required this.userName,
    required this.userProfile,
    required this.userNumber,
    required this.userBio,
    required this.roomId,
  });

  String get _displayNumber =>
      userNumber.startsWith('+91') ? userNumber : '+91 $userNumber';

  @override
  Widget build(BuildContext context) {
    final contactController = Get.find<ContactController>();
    final homeController = Get.find<HomeController>();
    final chatController = Get.find<ChatController>();

    return Scaffold(
      backgroundColor: CustomColor.kBackground,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHero(homeController, chatController),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xxl.w, AppSpacing.xl.h,
                AppSpacing.xxl.w, AppSpacing.xsection.h),
            child: Entrance(
              duration: const Duration(milliseconds: 380),
              slideOffset: const Offset(0, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactCard(),
                  SizedBox(height: AppSpacing.xxl.h),
                  _buildSettingsCard(context, contactController),
                  SizedBox(height: AppSpacing.xxl.h),
                  SharedMediaStrip(roomId: roomId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gradient hero (matches PremiumChatHeader) ────────────────────────────
  Widget _buildHero(
      HomeController homeController, ChatController chatController) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CustomColor.kPrimaryLight, CustomColor.kBackground],
        ),
      ),
      child: SafeArea(
        bottom: true,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg.w, AppSpacing.sm.h, AppSpacing.lg.w, 0),
          child: Column(
            children: [
              Row(
                children: [
                  const AppBackButton(),
                  const Spacer(),
                  Text(
                    'Profile',
                    style: AppTextStyles.headingMd.copyWith(
                      color: CustomColor.kTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: 40.r),
                ],
              ),
              SizedBox(height: AppSpacing.xl.h),
              Obx(() {
                final isOnline = homeController.onlineUsers
                    .any((u) => u.userId == chatController.receiverId);
                return _buildHeroAvatar(isOnline);
              }),
              SizedBox(height: AppSpacing.lg.h),
              Text(
                userName.isEmpty ? 'Humming Bird User' : userName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingXl.copyWith(
                  color: CustomColor.kTextPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (userBio.isNotEmpty) ...[
                SizedBox(height: AppSpacing.xxs.h),
                Text(
                  userBio,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: CustomColor.kTextSecondary,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.md.h),
              _buildNumberPill(),
              SizedBox(height: AppSpacing.lg.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuickAction(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () {},
                  ),
                  SizedBox(width: AppSpacing.xxxl.w),
                  _QuickAction(
                    icon: Icons.notifications_off_rounded,
                    label: 'Mute',
                    onTap: () {},
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAvatar(bool isOnline) {
    return GestureDetector(
      onTap: userProfile.isEmpty
          ? null
          : () => Get.to(
                () => FullScreenImageView(
                  url: '${Endpoints.mediaBaseUrl}$userProfile',
                ),
              ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(3.r),
            decoration: BoxDecoration(
              gradient: isOnline
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CustomColor.kPrimaryMedium,
                        CustomColor.kPrimaryLight,
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CustomColor.kLightBorder,
                        CustomColor.kLightBorder
                      ],
                    ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 56.r,
              backgroundColor: CustomColor.kWhite,
              backgroundImage: userProfile.isNotEmpty
                  ? CachedNetworkImageProvider(
                      '${Endpoints.mediaBaseUrl}$userProfile')
                  : const AssetImage(AppAssets.defaultProfilePic)
                      as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
          ),
          if (isOnline)
            Positioned(
              right: 4.r,
              bottom: 4.r,
              child: Container(
                width: 18.r,
                height: 18.r,
                decoration: BoxDecoration(
                  color: CustomColor.kOnlineGreen,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: CustomColor.kTextOnDark, width: 2.5.r),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNumberPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
        border: Border.all(color: CustomColor.kLightBorder),
        boxShadow: AppShadow.cardLight,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone_rounded,
              size: 14.r, color: CustomColor.kPrimaryColor),
          SizedBox(width: 6.w),
          Text(
            _displayNumber,
            style: AppTextStyles.subtitle.copyWith(
              color: CustomColor.kTextSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body cards ───────────────────────────────────────────────────────────
  Widget _buildContactCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl.r),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(color: CustomColor.kLightBorder),
        boxShadow: AppShadow.cardLight,
      ),
      child: Row(
        children: [
          Container(
            width: (AppIcons.big + 8).r,
            height: (AppIcons.big + 8).r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CustomColor.kPrimaryLight,
              borderRadius: BorderRadius.circular(AppRadius.xl.r),
            ),
            child: Icon(Icons.phone_rounded,
                color: CustomColor.kPrimaryColor, size: AppIcons.lg.r),
          ),
          SizedBox(width: AppSpacing.xl.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phone number',
                  style: AppTextStyles.bodySm.copyWith(
                    color: CustomColor.kTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs.h),
                Text(
                  _displayNumber,
                  style: AppTextStyles.titleSm.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          PressScale(
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _displayNumber));
                HapticFeedback.lightImpact();
              },
              borderRadius: BorderRadius.circular(AppRadius.pill.r),
              child: Container(
                width: AppDimensions.buttonHeightMd.r,
                height: AppDimensions.buttonHeightMd.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CustomColor.kPrimaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                ),
                child: Icon(Icons.copy_rounded,
                    color: CustomColor.kPrimaryColor, size: AppIcons.md.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
      BuildContext context, ContactController contactController) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(color: CustomColor.kLightBorder),
        boxShadow: AppShadow.cardLight,
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Chat',
            danger: true,
            onTap: () => showDialog(
              context: context,
              builder: (_) => DeleteRoomDialog(
                roomId: roomId,
                fromUserInfo: true,
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.block_rounded,
            label: contactController.checkIfUserIsBlocked(
                    contactController.getUserIdByNumber(userNumber))
                ? 'Unblock $userName'
                : 'Block $userName',
            danger: true,
            showDivider: true,
            onTap: () {
              final id = contactController.getUserIdByNumber(userNumber);
              showDialog(
                context: context,
                builder: (_) => BlockUserDialog(userId: id, userName: userName),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.thumb_down_off_alt_outlined,
            label: 'Report ${userName.split(' ')[0]}',
            danger: true,
            showDivider: true,
            onTap: () => showDialog(
              context: context,
              builder: (_) => ReportDialog(
                userId: contactController.getUserIdByNumber(userNumber),
                userName: userName.split(' ')[0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 52.r,
              width: 52.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CustomColor.kWhite,
                shape: BoxShape.circle,
                boxShadow: AppShadow.cardLight,
              ),
              child: Icon(icon,
                  color: CustomColor.kPrimaryColor, size: AppIcons.xl.r),
            ),
            SizedBox(height: AppSpacing.sm.h),
            Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: CustomColor.kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final bool showDivider;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.danger = false,
    this.showDivider = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl.w, vertical: AppSpacing.xl.h),
            child: Row(
              children: [
                Container(
                  height: AppDimensions.inputHeightSm.r,
                  width: AppDimensions.inputHeightSm.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: danger
                        ? CustomColor.kDangerRed.withValues(alpha: 0.08)
                        : CustomColor.kPrimaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg.r),
                  ),
                  child: Icon(
                    icon,
                    size: AppIcons.md.r,
                    color: danger
                        ? CustomColor.kDangerRed
                        : CustomColor.kPrimaryColor,
                  ),
                ),
                SizedBox(width: AppSpacing.xl.w),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.titleSm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: danger
                          ? CustomColor.kDangerRed
                          : CustomColor.kTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.xxl.w),
            child: Divider(
              height: 1,
              thickness: 1,
              color: CustomColor.kTextTertiary.withValues(alpha: 0.08),
            ),
          ),
      ],
    );
  }
}
