import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/groups/add_member_bottom_sheet.dart';
import 'package:humming_bird/components/groups/admin_container.dart';
import 'package:humming_bird/components/groups/group_image_picker_bottom_sheet.dart';
import 'package:humming_bird/components/groups/group_members_option_dialog.dart';
import 'package:humming_bird/components/groups/group_name_dialog.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/media/shared_media_strip.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class GroupInfo extends StatelessWidget {
  final String groupName;
  final String roomId;
  const GroupInfo({super.key, required this.groupName, required this.roomId});

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.find();
    ContactController contactController = Get.find();
    UserController userController = Get.find();
    return Scaffold(

      body: Obx(
        () => groupController.showLoading.value
            ? const CustomLoading()
            : GetBuilder<GroupController>(
                builder: (_) => SafeArea(
                  bottom: true,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildHero(context, groupController),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            AppSpacing.xxl.w,
                            AppSpacing.xl.h,
                            AppSpacing.xxl.w,
                            AppSpacing.xsection.h),
                        child: Entrance(
                          duration: const Duration(milliseconds: 380),
                          slideOffset: const Offset(0, 24),
                          child: Column(
                            children: [
                              _buildActions(context, groupController),
                              SizedBox(height: AppSpacing.xxl.h),
                              _buildMembersSection(context, groupController,
                                  contactController, userController),
                              SizedBox(height: AppSpacing.xxl.h),
                              SharedMediaStrip(roomId: roomId),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Soft gradient hero (matches UserProfileDetails) ──────────────────────
  Widget _buildHero(BuildContext context, GroupController groupController) {
    final isAdmin = groupController.checkIfUserAdmin();
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
          padding: EdgeInsets.fromLTRB(AppSpacing.lg.w, AppSpacing.sm.h,
              AppSpacing.lg.w, AppSpacing.xl.h),
          child: Column(
            children: [
              Row(
                children: [
                  const AppBackButton(),
                  const Spacer(),
                  Text(
                    'Group Info',
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
              _buildGroupAvatar(context, isAdmin, groupController),
              SizedBox(height: AppSpacing.lg.h),
              GetBuilder<ContactController>(
                id: 'Update Group',
                builder: (_) {
                  final name = groupController.getUpdatedGroup(roomId).rName ??
                      groupName;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headingXl.copyWith(
                            color: CustomColor.kTextPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isAdmin) ...[
                        SizedBox(width: AppSpacing.sm.w),
                        PressScale(
                          child: GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => GroupNameDialog(roomId: roomId),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(AppSpacing.md.r),
                              decoration: BoxDecoration(
                                color: CustomColor.kWhite,
                                shape: BoxShape.circle,
                                boxShadow: AppShadow.cardLight,
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                size: AppIcons.sm.r,
                                color: CustomColor.kPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text(
                groupController.groupData?.room?.rCreatedAt != null
                    ? 'Created on ${AppHelper.formatDateTime(DateTime.parse(groupController.groupData!.room!.rCreatedAt!), 'dd MMM yyyy')}'
                    : '',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm
                    .copyWith(color: CustomColor.kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(
      BuildContext context, bool isAdmin, GroupController groupController) {
    return SizedBox(
      height: 120.r,
      width: 120.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xxs.r),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CustomColor.kPrimaryMedium,
                  CustomColor.kPrimaryLight,
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 58.r,
              // backgroundColor: CustomColor.kWhite,
              backgroundImage: groupController.getGroupImage(roomId),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          if (isAdmin)
            Positioned(
              bottom: 4.r,
              right: 4.r,
              child: PressScale(
                child: GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    useSafeArea: true,
                    builder: (_) => GroupImagePickerBottomSheet(roomId: roomId),
                  ),
                  child: Container(
                    height: 34.r,
                    width: 34.r,
                    decoration: BoxDecoration(
                      color: CustomColor.kWhite,
                      shape: BoxShape.circle,
                      boxShadow: AppShadow.cardLight,
                    ),
                    child: Icon(
                      Icons.add_a_photo,
                      size: AppIcons.md.r,
                      color: CustomColor.kDarkPrimaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, GroupController groupController) {
    final isMuted = groupController.groupData?.room?.rStatus == '0';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (groupController.checkIfAdmin())
          _ActionButton(
            icon: Icons.person_add_rounded,
            label: 'Add',
            color: CustomColor.kSuccess,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              useSafeArea: true,
              builder: (_) => AddMemberBottomSheet(roomId: roomId),
            ),
          ),
        _ActionButton(
          icon: isMuted
              ? Icons.notifications_active_rounded
              : Icons.notifications_off_rounded,
          label: isMuted ? 'Unmute' : 'Mute',
          color: isMuted ? CustomColor.kGoldAccent : CustomColor.kPrimaryColor,
          onTap: () => groupController.toggleGroupMute(roomId),
        ),
        _ActionButton(
          icon: Icons.exit_to_app_rounded,
          label: 'Exit',
          color: CustomColor.kDangerRed,
          onTap: () => groupController.leaveGroup(roomId),
        ),
        if (groupController.checkIfUserAdmin())
          Obx(
            () => _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              color: CustomColor.kDangerRed,
              isLoading: groupController.isDeletingGroup.value,
              onTap: groupController.isDeletingGroup.value
                  ? null
                  : () => _confirmDeleteGroup(
                        context,
                        groupController,
                        roomId,
                      ),
            ),
          ),
      ],
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    GroupController groupController,
    ContactController contactController,
    UserController userController,
  ) {
    final members = groupController.groupData?.members ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Group Members',
              style:
                  AppTextStyles.headingSm.copyWith(fontWeight: FontWeight.w800),
            ),
            Obx(
              () => Container(
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
                    Icon(Icons.groups_rounded,
                        size: 14.r, color: CustomColor.kPrimaryColor),
                    SizedBox(width: 6.w),
                    Text(
                      '${groupController.groupMembers.value}',
                      style: AppTextStyles.subtitle.copyWith(
                        color: CustomColor.kTextSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl.h),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: CustomColor.kWhite,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(color: CustomColor.kLightBorder),
            boxShadow: AppShadow.cardLight,
          ),
          child: Column(
            children: [
              for (var i = 0; i < members.length; i++)
                Entrance(
                  delayFactor: (i % 8) * 0.05,
                  child: _MemberTile(
                    user: members[i],
                    isSelf: members[i].userId == userController.user?.userId,
                    displayName:
                        members[i].userId == userController.user?.userId
                            ? 'You'
                            : contactController.getAllContactsName(members[i]),
                    number: members[i].userMobileNum,
                    bio: (members[i].userBio?.isNotEmpty ?? false)
                        ? members[i].userBio!
                        : null,
                    isAdmin: groupController.checkIfAdmin(user: members[i]),
                    showDivider: i < members.length - 1,
                    onTap: members[i].userId == userController.user?.userId
                        ? null
                        : () => showAdaptiveDialog(
                              context: context,
                              builder: (_) => GroupMembersOptions(
                                roomId: roomId,
                                user: members[i],
                              ),
                            ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteGroup(
    BuildContext context,
    GroupController groupController,
    String roomId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.rounded.r),
        ),
        titlePadding: EdgeInsets.fromLTRB(
            AppSpacing.xxl.w, AppSpacing.xxl.h, AppSpacing.xxl.w, 0),
        contentPadding: EdgeInsets.fromLTRB(
            AppSpacing.xxl.w, AppSpacing.md.h, AppSpacing.xxl.w, 0),
        actionsPadding: EdgeInsets.fromLTRB(
            AppSpacing.xl.w, 0, AppSpacing.xl.w, AppSpacing.xl.h),
        title: Text(
          'Delete Group',
          style: AppTextStyles.headingMd.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will remove this group and its messages from your chat list.',
          style:
              AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyles.titleSm
                  .copyWith(color: CustomColor.kTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              groupController.deleteGroup(roomId);
            },
            style: TextButton.styleFrom(
              backgroundColor: CustomColor.kDangerRed.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
              ),
            ),
            child: Text(
              'Delete',
              style:
                  AppTextStyles.titleSm.copyWith(color: CustomColor.kDangerRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final User user;
  final bool isSelf;
  final String displayName;
  final String? number;
  final String? bio;
  final bool isAdmin;
  final bool showDivider;
  final VoidCallback? onTap;

  const _MemberTile({
    required this.user,
    required this.isSelf,
    required this.displayName,
    required this.number,
    required this.bio,
    required this.isAdmin,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (user.userImage?.isNotEmpty ?? false);
    return Column(
      children: [
        PressScale(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl.w, vertical: AppSpacing.xl.h),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: CustomColor.kUltraLightPrimary,
                    backgroundImage: hasImage
                        ? CachedNetworkImageProvider(
                            '${Endpoints.mediaBaseUrl}${user.userImage!}')
                        : const AssetImage(AppAssets.defaultProfilePic)
                            as ImageProvider,
                    onBackgroundImageError: hasImage ? (_, __) {} : null,
                  ),
                  SizedBox(width: AppSpacing.xl.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleSm.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isAdmin) ...[
                              SizedBox(width: AppSpacing.sm.w),
                              const AdminContainer(),
                            ],
                          ],
                        ),
                        if (number != null && number!.isNotEmpty) ...[
                          SizedBox(height: AppSpacing.xxs.h),
                          Text(
                            number!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                        if (bio != null &&
                            (isSelf || number == null || number!.isEmpty)) ...[
                          SizedBox(height: AppSpacing.xxs.h),
                          Text(
                            bio!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isSelf)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: AppIcons.xl.r,
                      color: CustomColor.kTextTertiary,
                    ),
                ],
              ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isLoading ? 0.6 : 1.0,
      child: PressScale(
        child: GestureDetector(
          onTap: isLoading ? null : onTap,
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
                child: isLoading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, color: color, size: AppIcons.xl.r),
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
      ),
    );
  }
}
