import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/controllers/profile_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/profile/qr_code_bottom_sheet.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/image_viewer_widget.dart';
import 'package:humming_bird/pages/profile/profile_edit.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_dimensions.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ProfileController profileController = Get.put(ProfileController());
  final UserController userController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Profile', actions: [
        IconButton(
          tooltip: 'Edit profile',
          onPressed: () => Get.to(() => const UpdateProfile()),
          icon: const Icon(Icons.edit_rounded),
        ),
      ]),
      body: SafeArea(
        child: GetBuilder<ProfileController>(
          id: 'update-profile',
          builder: (_) {
            final user = userController.user;
            final name =
                '${user?.userFirstName ?? ''} ${user?.userLastName ?? ''}'
                    .trim();
            final image = user?.userImage ?? '';

            return Entrance(
                duration: const Duration(milliseconds: 380),
                slideOffset: const Offset(0, 24),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xxl.w,
                      AppSpacing.xl.h, AppSpacing.xxl.w, AppSpacing.xsection.h),
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.xxxl.r),
                      decoration: BoxDecoration(
                        color: CustomColor.kDarkSurface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.rounded.r),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: image.isEmpty
                                ? null
                                : () => Get.to(
                                      () => FullScreenImageView(
                                        url: '${Endpoints.mediaBaseUrl}$image',
                                      ),
                                    ),
                            child: Container(
                              padding: EdgeInsets.all(AppSpacing.xxs.r),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    CustomColor.kPrimaryColor,
                                    CustomColor.kGoldAccent,
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: (AppDimensions.avatarProfile - 22).r,
                                backgroundColor: CustomColor.kWhite,
                                backgroundImage: image.isNotEmpty
                                    ? NetworkImage(
                                        '${Endpoints.mediaBaseUrl}$image')
                                    : const AssetImage(
                                            AppAssets.defaultProfilePic)
                                        as ImageProvider,
                                onBackgroundImageError: (_, __) {},
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.xxl.h - 2.h),
                          Text(
                            name.isEmpty ? 'Humming Bird User' : name,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headingXl.copyWith(
                                color: CustomColor.kWhite,
                                fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: AppSpacing.xs.h),
                          Text(
                            user?.userMobileNum ?? '',
                            style: AppTextStyles.subtitle.copyWith(
                                color:
                                    CustomColor.kWhite.withValues(alpha: 0.68)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    _InfoTile(
                      icon: Icons.mail_rounded,
                      label: 'Email',
                      value: user?.userEmail ?? 'Not added',
                    ),
                    _InfoTile(
                      icon: Icons.self_improvement_rounded,
                      label: 'Bio',
                      value: user?.userBio ?? 'Not added',
                    ),
                    _InfoTile(
                      icon: Icons.cake_rounded,
                      label: 'Date of birth',
                      value: (user?.userDob ?? '').trim().isEmpty
                          ? 'Not added'
                          : AppHelper.formatDobForDisplay(user?.userDob),
                    ),
                    _QrCodeTile(name: name),
                  ],
                ));
          },
        ),
      ),
    );
  }
}

class _QrCodeTile extends StatelessWidget {
  final String name;
  const _QrCodeTile({required this.name});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ProfileQrCodeSheet.show(context, name: name),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.lg.h),
        padding: EdgeInsets.all(AppSpacing.xl.r),
        decoration: BoxDecoration(
          color: CustomColor.kWhite,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
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
              child: Icon(Icons.qr_code_rounded,
                  color: CustomColor.kPrimaryColor, size: AppIcons.lg.r),
            ),
            SizedBox(width: AppSpacing.xl.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Code',
                    style: AppTextStyles.bodySm.copyWith(
                        color: CustomColor.kTextSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: AppSpacing.xxs.h),
                  Text(
                    'Share your profile',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSm
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: CustomColor.kTextTertiary, size: AppIcons.xl.r),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.lg.h),
      padding: EdgeInsets.all(AppSpacing.xl.r),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
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
            child: Icon(icon,
                color: CustomColor.kPrimaryColor, size: AppIcons.lg.r),
          ),
          SizedBox(width: AppSpacing.xl.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySm.copyWith(
                      color: CustomColor.kTextSecondary,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.xxs.h),
                Text(
                  value.isEmpty ? 'Not added' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
