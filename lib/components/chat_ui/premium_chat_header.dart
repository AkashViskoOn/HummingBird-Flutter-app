import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/chat_ui/premium_popup_menu.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/pages/groups/group_info.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/user_profile_details.dart';

class PremiumChatHeader extends StatelessWidget {
  final String name;
  final String userNumber;
  final String roomId;
  final String receiverId;
  final bool isGroup;
  final String userBio;
  final String userProfile;
  final VoidCallback onBack;
  final bool isPending;

  const PremiumChatHeader({
    super.key,
    required this.name,
    required this.userNumber,
    required this.roomId,
    required this.receiverId,
    required this.isGroup,
    this.userBio = '',
    this.userProfile = '',
    required this.onBack,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final homeController = Get.find<HomeController>();
    final groupController = Get.find<GroupController>();
    final contactController = Get.find<ContactController>();

    return Obx(() {
      final isMultiSelect = chatController.messageSelectorMap.isNotEmpty;
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: isMultiSelect ? 56.h : 76.h,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [CustomColor.kPrimaryColor, CustomColor.kPrimaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(vertical: isMultiSelect ? 6.h : 8.h),
              child: isMultiSelect
                  ? _buildMultiSelectHeader(chatController)
                  : _buildNormalHeader(
                      context,
                      chatController,
                      homeController,
                      groupController,
                      contactController,
                    ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildMultiSelectHeader(ChatController chatController) {
    return Row(
      children: [
        SizedBox(width: AppSpacing.sm.w),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          onTap: () {
            chatController.messageSelectorMap.value = {};
            chatController.youMessages.clear();
            chatController.isMultiSelectMode.value = false;
          },
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md.r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close_rounded,
                    size: AppIcons.xxxl.r, color: CustomColor.kTextOnDark),
                SizedBox(width: AppSpacing.sm.w),
                Text(
                  '${chatController.messageSelectorMap.length}',
                  style:
                      AppTextStyles.titleMd.copyWith(color: CustomColor.kWhite),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Select All',
          onPressed: () {
            final allIds = chatController.messages.map((m) => m.mId!).toSet();
            chatController.messageSelectorMap.value = {
              for (final id in allIds) id: true,
            };
          },
          icon: Icon(Icons.select_all_rounded,
              size: AppIcons.xl.r, color: CustomColor.kTextOnDark),
        ),
        SizedBox(width: AppSpacing.sm.w),
      ],
    );
  }

  Widget _buildNormalHeader(
    BuildContext context,
    ChatController chatController,
    HomeController homeController,
    GroupController groupController,
    ContactController contactController,
  ) {
    final isOnline = !isGroup &&
        homeController.onlineUsers.any((u) => u.userId == receiverId);

    return Row(
      children: [
        SizedBox(width: AppSpacing.xs.w),
        _buildBackButton(),
        SizedBox(width: AppSpacing.sm.w),
        isGroup
            ? GetBuilder<ContactController>(
                id: 'Update Group',
                builder: (_) =>
                    _buildAvatar(context, isOnline, groupController),
              )
            : _buildAvatar(context, isOnline, groupController),
        SizedBox(width: AppSpacing.lg.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isGroup
                  ? GetBuilder<ContactController>(
                      id: 'Update Group',
                      builder: (_) {
                        final groupName =
                            groupController.getUpdatedGroup(roomId).rName;
                        return Text(
                          (groupName != null && groupName.isNotEmpty)
                              ? groupName
                              : name,
                          style: AppTextStyles.titleMd
                              .copyWith(color: CustomColor.kWhite),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    )
                  : Text(
                      name,
                      style: AppTextStyles.titleMd
                          .copyWith(color: CustomColor.kWhite),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              SizedBox(height: 2.h),
              Obx(() {
                chatController.showTyping.value;
                return _buildStatus(context, chatController, homeController);
              }),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.sm.w),
        _buildActions(context, chatController),
        SizedBox(width: AppSpacing.sm.w),
      ],
    );
  }

  Widget _buildBackButton() {
    return AppBackButton(color: CustomColor.kTextOnDark, onTap: onBack);
  }

  Widget _buildAvatar(
    BuildContext context,
    bool isOnline,
    GroupController groupController,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill.r),
      onTap: () {
        if (isGroup) {
          groupController.fetchGroupInfo(roomId);
          Get.to(() => GroupInfo(
                groupName: name,
                roomId: roomId,
              ));
        } else {
          Get.to(() => UserProfileDetails(
                userName: name,
                userProfile: userProfile,
                userNumber: userNumber,
                userBio: userBio,
                roomId: roomId,
              ));
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: EdgeInsets.all(2.r),
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
                        CustomColor.kPrimaryLight,
                        CustomColor.kPrimaryLight,
                      ],
                    ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 24.r,
              backgroundImage: isGroup
                  ? groupController.getGroupImage(roomId)
                  : userProfile.isNotEmpty
                      ? CachedNetworkImageProvider(
                              '${Endpoints.mediaBaseUrl}$userProfile')
                          as ImageProvider
                      : const AssetImage(AppAssets.defaultProfilePic),
              onBackgroundImageError: (_, __) {},
            ),
          ),
          if (isOnline)
            Positioned(
              right: 1.r,
              bottom: 1.r,
              child: Container(
                width: 12.r,
                height: 12.r,
                decoration: BoxDecoration(
                  color: CustomColor.kOnlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CustomColor.kTextOnDark,
                    width: 2.r,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatus(
    BuildContext context,
    ChatController chatController,
    HomeController homeController,
  ) {
    if (isGroup) {
      return GetBuilder<GroupController>(
        builder: (_) {
          if (chatController.showTyping.value) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12.r,
                  height: 12.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.r,
                    color: CustomColor.kTextOnDark.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(width: AppSpacing.xs.w),
                Text(
                  'Typing...',
                  style: AppTextStyles.bodySm.copyWith(
                      color: CustomColor.kTextOnDark.withValues(alpha: 0.9)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }

          final members =
              Get.find<GroupController>().groupData?.members ?? const <User>[];
          if (members.isEmpty) {
            return Row(
              children: [
                Icon(Icons.group_rounded,
                    size: 12.r,
                    color: CustomColor.kTextOnDark.withValues(alpha: 0.6)),
                SizedBox(width: AppSpacing.xs.w),
                Text(
                  'Group chat',
                  style: AppTextStyles.bodySm.copyWith(
                      color: CustomColor.kTextOnDark.withValues(alpha: 0.72)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final member in members.take(3))
                  _buildMemberAvatar(member),
                if (members.length > 3)
                  _buildMoreMembersChip(members.length - 3),
              ],
            ),
          );
        },
      );
    }

    if (chatController.showTyping.value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12.r,
            height: 12.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.r,
              color: CustomColor.kTextOnDark.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(width: AppSpacing.xs.w),
          Text(
            'Typing...',
            style: AppTextStyles.bodySm.copyWith(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.9)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    if (isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded,
              size: 12.r,
              color: CustomColor.kTextOnDark.withValues(alpha: 0.6)),
          SizedBox(width: AppSpacing.xs.w),
          Text(
            'Not using Humming Bird yet',
            style: AppTextStyles.bodySm.copyWith(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.72)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    final isOnline =
        homeController.onlineUsers.any((u) => u.userId == receiverId);
    if (isOnline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.r,
            height: 6.r,
            decoration: const BoxDecoration(
              color: CustomColor.kOnlineGreen,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSpacing.xs.w),
          Text(
            'Online',
            style:
                AppTextStyles.bodySm.copyWith(color: CustomColor.kOnlineGreen),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      userNumber,
      style: AppTextStyles.bodySm
          .copyWith(color: CustomColor.kTextOnDark.withValues(alpha: 0.72)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions(
    BuildContext context,
    ChatController chatController,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isGroup && receiverId.isNotEmpty) ...[
          _buildActionButton(
            icon: Icons.call_rounded,
            tooltip: 'Voice call',
            onPressed: () {
              Get.find<CallController>().initCall(receiverId, 'audio');
            },
          ),
          _buildActionButton(
            icon: Icons.videocam_rounded,
            tooltip: 'Video call',
            onPressed: () {
              Get.find<CallController>().initCall(receiverId, 'video');
            },
          ),
        ],
        // _buildActionButton(
        //   icon: Icons.star_outline_rounded,
        //   tooltip: 'Starred messages',
        //   onPressed: () {
        //     Get.to(() => const StarredMessagesPage());
        //   },
        // ),
        PremiumChatMenu(
          userName: name,
          userNumber: userNumber,
          roomId: roomId,
          receiverId: receiverId,
          isGroup: isGroup,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 2.r),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: AppIcons.xl.r, color: CustomColor.kTextOnDark),
        splashRadius: 20.r,
        padding: EdgeInsets.all(AppSpacing.sm.r),
        constraints: BoxConstraints(minWidth: 40.r, minHeight: 40.r),
      ),
    );
  }

  Widget _buildMemberAvatar(User member) {
    final hasImage = member.userImage?.isNotEmpty == true;
    return Container(
      margin: EdgeInsets.only(right: 4.r),
      decoration: BoxDecoration(
        color: CustomColor.kTextOnDark,
        shape: BoxShape.circle,
        border: Border.all(color: CustomColor.kTextOnDark, width: 1.2.r),
      ),
      child: CircleAvatar(
        radius: 9.r,
        backgroundColor: CustomColor.kTextOnDark.withValues(alpha: 0.25),
        foregroundImage: hasImage
            ? CachedNetworkImageProvider(
                '${Endpoints.mediaBaseUrl}${member.userImage}')
            : null,
        onForegroundImageError: hasImage ? (_, __) {} : null,
        child: Text(
          _initialsFor(member),
          style: TextStyle(
            fontSize: 7.sp,
            fontWeight: FontWeight.w700,
            color: CustomColor.kTextOnDark,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreMembersChip(int extraCount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: CustomColor.kTextOnDark.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
        border:
            Border.all(color: CustomColor.kTextOnDark.withValues(alpha: 0.25)),
      ),
      child: Text(
        '+$extraCount',
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: CustomColor.kTextOnDark,
        ),
      ),
    );
  }

  String _initialsFor(User member) {
    final first = member.userFirstName ?? '';
    final last = member.userLastName ?? '';
    final initials = '${first.isNotEmpty ? first[0] : ''}'
            '${last.isNotEmpty ? last[0] : ''}'
        .trim();
    return initials.isEmpty ? '?' : initials.toUpperCase();
  }
}
