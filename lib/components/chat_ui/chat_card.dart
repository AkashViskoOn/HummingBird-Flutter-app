import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/image_viewer_widget.dart';
import 'package:humming_bird/res/app_assets.dart';

import 'delete_room_dialog.dart';

class ChatCard extends StatefulWidget {
  final String name;
  final String lastMessage;
  final String lastMessageTime;
  final String newMessageCounter;
  final String roomUsers;
  final String roomId;
  final String receiverId;
  final bool isGroup;
  final String userNumber;
  final String userBio;

  const ChatCard({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.newMessageCounter,
    required this.roomUsers,
    required this.roomId,
    required this.receiverId,
    this.isGroup = false,
    this.userNumber = '',
    this.userBio = '',
  });

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  late GroupController groupController;

  HomeController homeController = Get.find();
  ChatController chatController = Get.find();
  ContactController contactController = Get.find();
  UserController userController = Get.find();

  String profilePic = '';

  @override
  void initState() {
    if (!widget.isGroup) {
      _updateProfilePic();
    } else {
      groupController = Get.find();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ChatCard oldWidget) {
    if (!widget.isGroup) _updateProfilePic();
    super.didUpdateWidget(oldWidget);
  }

  void _updateProfilePic() async {
    profilePic = await homeController.getUserProfilePic(widget.roomUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      startActionPane: widget.isGroup
          ? null
          : ActionPane(
              motion: const StretchMotion(),
              extentRatio: 0.35,
              children: [
                SlidableAction(
                  borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                  onPressed: (_) {},
                  icon: Icons.phone_rounded,
                  foregroundColor: CustomColor.kTextOnDark,
                  backgroundColor: CustomColor.kSuccessFill,
                  label: 'Call',
                ),
              ],
            ),
      endActionPane: widget.isGroup
          ? null
          : ActionPane(
              motion: const StretchMotion(),
              extentRatio: 0.35,
              children: [
                SlidableAction(
                  borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                  onPressed: (_) => showDialog(
                    context: context,
                    builder: (_) => DeleteRoomDialog(roomId: widget.roomId),
                  ),
                  icon: Icons.delete_rounded,
                  foregroundColor: CustomColor.kTextOnDark,
                  backgroundColor: CustomColor.kDangerFill,
                  label: 'Delete',
                ),
              ],
            ),
      child: InkWell(
        onTap: () {
          userController.inHomeScreen = false;
          homeController.makeUnreadReadMessage(widget.roomId);
          homeController.update();
          chatController.receiverId = widget.receiverId;

          Get.to(() => ChatScreen(
                name: widget.name,
                userNumber: widget.userNumber,
                roomId: widget.roomId,
                receiverId: '',
                isGroup: widget.isGroup,
                userBio: widget.userBio,
                userProfile: profilePic,
              ));
        },
        splashColor: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
        highlightColor: CustomColor.kPrimaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        child: Obx(
          () => AnimatedContainer(
            duration: AppAnimation.normal,
            margin: EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl.w, vertical: AppSpacing.xs.h),
            padding: EdgeInsets.all(AppSpacing.xl.r),
            decoration: BoxDecoration(
              color: chatController.selectedRoomList.contains(widget.roomId)
                  ? CustomColor.kUltraLightPrimary
                  : CustomColor.kWhite,
              borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
              border: Border.all(
                color: chatController.selectedRoomList.contains(widget.roomId)
                    ? CustomColor.kPrimaryColor.withValues(alpha: 0.3)
                    : CustomColor.kLightBorder.withValues(alpha: 0.5),
              ),
              boxShadow: AppShadow.cardLight,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar section
                GetBuilder<HomeController>(
                  id: 'profile-pic',
                  builder: (_) => _AvatarWidget(
                    isGroup: widget.isGroup,
                    profilePic: profilePic,
                    roomId: widget.roomId,
                    isSelected:
                        chatController.selectedRoomList.contains(widget.roomId),
                    groupController: widget.isGroup ? groupController : null,
                  ),
                ),

                SizedBox(width: AppSpacing.xl.w),

                // Name + last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name,
                        style: AppTextStyles.titleMd
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.xxs.h),
                      GetBuilder<ChatController>(
                        id: 'update-typing',
                        builder: (_) {
                          final isTyping = chatController.typingUsers
                              .contains(widget.receiverId);
                          return Row(
                            children: [
                              if (isTyping)
                                Container(
                                  width: AppSpacing.sm.r,
                                  height: AppSpacing.sm.r,
                                  margin:
                                      EdgeInsets.only(right: AppSpacing.xs.w),
                                  decoration: const BoxDecoration(
                                    color: CustomColor.kOnlineGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  isTyping ? 'Typing…' : widget.lastMessage,
                                  style: isTyping
                                      ? AppTextStyles.label.copyWith(
                                          color: CustomColor.kOnlineGreen,
                                          letterSpacing: null,
                                        )
                                      : AppTextStyles.chatPreview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Right column: time + badge + schedule btn
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.lastMessageTime,
                      style: AppTextStyles.helper
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: AppSpacing.sm.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.newMessageCounter != '0')
                          Container(
                            constraints: BoxConstraints(
                                minWidth: AppSpacing.section.r,
                                minHeight: AppSpacing.section.r),
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm.w),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  CustomColor.kPrimaryColor,
                                  CustomColor.kPrimaryMedium
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl.r),
                            ),
                            child: Text(
                              widget.newMessageCounter,
                              style: AppTextStyles.chatBadge,
                            ),
                          ),
                        SizedBox(width: AppSpacing.sm.w),
                        GestureDetector(
                          onTap: () {
                            userController.inHomeScreen = false;
                            homeController.makeUnreadReadMessage(widget.roomId);
                            homeController.update();
                            chatController.receiverId = widget.receiverId;
                            Get.to(() => ChatScreen(
                                  name: widget.name,
                                  roomId: widget.roomId,
                                  receiverId: widget.receiverId,
                                  isGroup: true,
                                  openScheduleSheet: true,
                                ));
                          },
                          child: Container(
                            width: AppSpacing.page.r,
                            height: AppSpacing.page.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CustomColor.kPrimaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg.r),
                            ),
                            child: Icon(
                              Icons.schedule_send_outlined,
                              color: CustomColor.kPrimaryColor,
                              size: AppIcons.md,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Avatar with online ring and group indicator ────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final bool isGroup;
  final String profilePic;
  final String roomId;
  final bool isSelected;
  final GroupController? groupController;

  const _AvatarWidget({
    required this.isGroup,
    required this.profilePic,
    required this.roomId,
    required this.isSelected,
    this.groupController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 52.r,
          height: 52.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                CustomColor.kPrimaryColor.withValues(alpha: 0.2),
                CustomColor.kPrimaryMedium.withValues(alpha: 0.1),
              ],
            ),
          ),
          padding: EdgeInsets.all(AppSpacing.xxs.r),
          child: isGroup
              ? InkWell(
                  onTap: () => Get.to(() => FullScreenImageView(
                      url: '',
                      imageProvider: groupController!.getGroupImage(roomId))),
                  child: CircleAvatar(
                    radius: 22.r,
                    backgroundImage: groupController!.getGroupImage(roomId),
                    onBackgroundImageError: (_, __) {},
                  ),
                )
              : profilePic.isNotEmpty
                  ? InkWell(
                      onTap: () => Get.to(() => FullScreenImageView(
                          url: '${Endpoints.mediaBaseUrl}$profilePic')),
                      child: CircleAvatar(
                        radius: 22.r,
                        backgroundImage: CachedNetworkImageProvider(
                            '${Endpoints.mediaBaseUrl}$profilePic'),
                        onBackgroundImageError: (_, __) {},
                      ),
                    )
                  : CircleAvatar(
                      radius: 22.r,
                      backgroundImage:
                          const AssetImage(AppAssets.defaultProfilePic),
                    ),
        ),

        // Bottom-right badge: check (selected), group, or nothing
        if (isSelected)
          Container(
            width: 18.r,
            height: 18.r,
            decoration: const BoxDecoration(
              color: CustomColor.kOnlineGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                size: 11.r, color: CustomColor.kTextOnDark),
          )
        else if (isGroup)
          Container(
            width: 18.r,
            height: 18.r,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CustomColor.kPrimaryColor, CustomColor.kPrimaryMedium],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: CustomColor.kTextOnDark, width: 1.5),
            ),
            child: Icon(Icons.group_rounded,
                size: 10.r, color: CustomColor.kTextOnDark),
          ),
      ],
    );
  }
}
