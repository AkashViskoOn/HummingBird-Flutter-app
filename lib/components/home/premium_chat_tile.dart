import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/chat_ui/chat_tile_context_menu.dart';
import 'package:humming_bird/components/chat_ui/group_context_sheet.dart';
import 'package:humming_bird/components/chat_ui/sent_seen_icon.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/pages/groups/group_info.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class PremiumChatTile extends StatefulWidget {
  final Rooms room;
  final String name;
  final String lastMessage;
  final String lastMessageTime;
  final String newMessageCounter;
  final String roomId;
  final String receiverId;
  final bool isGroup;
  final String userNumber;
  final String userBio;
  final bool isPinned;
  final bool isMuted;
  final bool isScheduled;
  final String? scheduledTime;
  final String? scheduledMessage;
  final bool isFavorite;
  final bool isArchived;
  final String? messageStatus;
  final String? searchQuery;
  final VoidCallback? onArchive;
  final VoidCallback? onToggleUnread;
  final bool isPending;
  final bool isSelected;
  final VoidCallback? onSelect;

  const PremiumChatTile({
    super.key,
    required this.room,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.newMessageCounter,
    required this.roomId,
    required this.receiverId,
    this.isGroup = false,
    this.userNumber = '',
    this.userBio = '',
    this.isPinned = false,
    this.isMuted = false,
    this.isScheduled = false,
    this.scheduledTime,
    this.scheduledMessage,
    this.isFavorite = false,
    this.isArchived = false,
    this.messageStatus,
    this.searchQuery,
    this.onArchive,
    this.onToggleUnread,
    this.isPending = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<PremiumChatTile> createState() => _PremiumChatTileState();
}

class _PremiumChatTileState extends State<PremiumChatTile>
    with TickerProviderStateMixin {
  HomeController homeController = Get.find();
  ChatController chatController = Get.find();

  void _openScheduleSheet() {
    userController.inHomeScreen = false;
    homeController.makeUnreadReadMessage(widget.roomId);
    homeController.update();
    chatController.receiverId = widget.receiverId;
    Get.to(() => ChatScreen(
          name: widget.name,
          userNumber: widget.userNumber,
          roomId: widget.roomId,
          receiverId: widget.receiverId,
          isGroup: widget.isGroup,
          userBio: widget.userBio,
          userProfile: profilePic,
          isPending: widget.isPending,
          openScheduleSheet: true,
        ));
  }

  ContactController contactController = Get.find();
  UserController userController = Get.find();

  String profilePic = '';
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;
  bool _isFavorite = false;
  bool _showHeart = false;

  late AnimationController _heartController;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    if (!widget.isGroup) _updateProfilePic();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
    _isFavorite = widget.isFavorite;

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(covariant PremiumChatTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isGroup) _updateProfilePic();
    if (oldWidget.isFavorite != widget.isFavorite) {
      _isFavorite = widget.isFavorite;
    }
    if (oldWidget.isPinned != widget.isPinned ||
        oldWidget.isArchived != widget.isArchived) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _updateProfilePic() async {
    profilePic =
        await homeController.getUserProfilePic(widget.room.rUsers ?? '');
    if (mounted) setState(() {});
  }

  void _onTap() {
    if (chatController.selectedRoomList.isNotEmpty) {
      widget.onSelect?.call();
      return;
    }
    userController.inHomeScreen = false;
    homeController.makeUnreadReadMessage(widget.roomId);
    homeController.update();
    chatController.receiverId = widget.receiverId;
    Get.to(() => ChatScreen(
          name: widget.name,
          userNumber: widget.userNumber,
          roomId: widget.roomId,
          receiverId: widget.receiverId,
          isGroup: widget.isGroup,
          userBio: widget.userBio,
          userProfile: profilePic,
          isPending: widget.isPending,
        ));
  }

  void _onDoubleTap() {
    _toggleFavorite();
    _showHeart = true;
    _heartController.forward().then((_) {
      if (mounted) {
        _heartController.reverse().then((_) {
          if (mounted) setState(() => _showHeart = false);
        });
      }
    });
  }

  void _toggleFavorite() {
    _isFavorite = !_isFavorite;
    homeController.update(['update-card']);
    homeController.toggleFavorite(widget.roomId);
  }

  void _togglePin() {
    homeController.togglePin(widget.roomId);
  }

  /// Shows the long-press menu (identical options) after tapping the "More"
  /// swipe action — same list the user already gets on a long press.
  void _openContextMenu() {
    final box = context.findRenderObject() as RenderBox?;
    final anchor = box != null
        ? box.localToGlobal(Offset(box.size.width - 20, box.size.height * 0.6))
        : Offset.zero;
    _showChatContextMenu(anchor);
  }

  void _showChatContextMenu(Offset position) {
    // Groups open the WhatsApp-style bottom sheet (icon + name + close header
    // with Group Info / Mute / Favourites / Clear Chat / Exit or Delete).
    if (widget.isGroup) {
      _openGroupContextSheet();
      return;
    }
    HapticFeedback.mediumImpact();
    final menuHasUnread = widget.newMessageCounter != '0';
    ChatTileContextMenu.show(
      context: context,
      position: position,
      isPinned: widget.isPinned,
      isMuted: widget.isMuted,
      isUnread: menuHasUnread,
      isArchived: widget.isArchived,
      isSelected: chatController.selectedRoomList.contains(widget.roomId),
      onSelect: () => chatController.manageRoomSelector(widget.roomId),
      onPin: _togglePin,
      onToggleUnread: () {
        if (menuHasUnread) {
          homeController.makeUnreadReadMessage(widget.roomId);
        } else {
          widget.onToggleUnread?.call();
        }
        homeController.update(['update-card']);
      },
      onArchive: () {
        widget.onArchive?.call();
      },
      onMute: () {
        _toggleMute();
        setState(() {});
      },
      onViewScheduled: () => _openScheduleSheet(),
      onViewContact: () {
        userController.inHomeScreen = false;
        chatController.receiverId = widget.receiverId;
        Get.to(() => ChatScreen(
              name: widget.name,
              userNumber: widget.userNumber,
              roomId: widget.roomId,
              receiverId: widget.receiverId,
              isGroup: widget.isGroup,
              userBio: widget.userBio,
              userProfile: profilePic,
              isPending: widget.isPending,
            ));
      },
      onDelete: _deleteChat,
    );
  }

  // ---------------------------------------------------------------------------
  // Group context bottom-sheet (WhatsApp-style)
  // ---------------------------------------------------------------------------

  void _openGroupContextSheet() {
    GroupContextSheet.show(
      context: context,
      groupName: widget.name.trim().isNotEmpty ? widget.name : 'Group',
      groupAvatar: widget.room.rAvatar ?? '',
      isAdmin: _isGroupAdmin(),
      isMuted: widget.isMuted,
      isFavorite: widget.isFavorite,
      onGroupInfo: () {
        Get.to(() => GroupInfo(
              groupName: widget.name.trim().isNotEmpty ? widget.name : 'Group',
              roomId: widget.roomId,
            ));
      },
      onClearChat: _clearChat,
      onToggleMute: () {
        _toggleMute();
        setState(() {});
      },
      onToggleFavorite: () {
        _toggleFavorite();
        setState(() {});
      },
      onExitGroup: _confirmExitGroup,
    );
  }

  void _confirmExitGroup() {
    final isAdmin = _isGroupAdmin();
    Get.defaultDialog(
      title: isAdmin ? 'Delete Group' : 'Exit Group',
      middleText: isAdmin
          ? 'Are you sure you want to delete this group?'
          : 'Are you sure you want to exit this group?',
      textCancel: 'Cancel',
      textConfirm: isAdmin ? 'Delete' : 'Exit',
      confirmTextColor: CustomColor.kTextOnDark,
      buttonColor: CustomColor.kDangerRed,
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'Cancel',
          style: AppTextStyles.headingSm
              .copyWith(color: CustomColor.kTextSecondary),
        ),
      ),
      confirm: TextButton(
        onPressed: () {
          if (isAdmin) {
            Get.find<GroupController>().deleteGroup(widget.roomId);
          } else {
            Get.find<GroupController>().leaveGroup(widget.roomId);
          }
          Get.back();
        },
        child: Text(isAdmin ? 'Delete' : 'Exit'),
      ),
    );
  }

  bool _isGroupAdmin() {
    try {
      final myId = userController.storage.read('userId')?.toString();
      final admins = jsonDecode(widget.room.rAdmins ?? '[]') as List;
      return admins.map((a) => a.toString()).contains(myId);
    } catch (_) {
      return false;
    }
  }

  void _clearChat() {
    Get.defaultDialog(
      title: 'Clear Chat',
      middleText: 'Delete all messages from this chat?',
      textCancel: 'Cancel',
      textConfirm: 'Clear',
      confirmTextColor: CustomColor.kTextOnDark,
      buttonColor: CustomColor.kDangerRed,
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'Cancel',
          style: AppTextStyles.headingSm
              .copyWith(color: CustomColor.kTextSecondary),
        ),
      ),
      confirm: TextButton(
        onPressed: _performClearChat,
        child: const Text('Clear'),
      ),
    );
  }

  void _performClearChat() {
    Get.back(); // close dialog
    try {
      final ids = LocalDatabase.getMessages(widget.roomId)
          .map((m) => m.mId ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      LocalDatabase.deleteMessages(ids);
      widget.room.rLastMessage = null;
      LocalDatabase.saveRooms([widget.room]);
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>()
            .messages
            .removeWhere((m) => m.mRoomId == widget.roomId);
        Get.find<ChatController>().update();
      }
    } catch (_) {}
    homeController.update(['update-card']);
  }

  void _toggleMute() {
    widget.room.rStatus = widget.room.rStatus == '1' ? '0' : '1';
    LocalDatabase.saveRooms([widget.room]);
    homeController.toggleMute(widget.roomId);
  }

  void _deleteChat() {
    Get.defaultDialog(
      title: 'Delete Chat',
      middleText: 'Are you sure you want to delete this chat?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: CustomColor.kTextOnDark,
      buttonColor: CustomColor.kDangerRed,
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'Cancel',
          style: AppTextStyles.headingSm
              .copyWith(color: CustomColor.kTextSecondary),
        ),
      ),
      onConfirm: () {
        homeController.deleteRoomAndSync(widget.roomId);
        Get.back();
      },
    );
  }

  String _getMediaSuffix(String? msgType) {
    switch (msgType?.trim()) {
      case '1':
        return 'Photo';
      case '2':
      case '5':
        return 'Document';
      case '3':
        return 'Audio';
      case '4':
        return 'Video';
      case '6':
        return 'Contact';
      case '7':
        return 'GIF';
      case '8':
        return 'Sticker';
      default:
        return '';
    }
  }

  IconData _getMediaIcon(String? msgType) {
    switch (msgType?.trim()) {
      case '1':
        return Icons.image_rounded;
      case '2':
      case '5':
        return Icons.description_rounded;
      case '3':
        return Icons.audiotrack_rounded;
      case '4':
        return Icons.videocam_rounded;
      case '6':
        return Icons.person_rounded;
      case '7':
        return Icons.gif_rounded;
      case '8':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Widget _buildScheduledPreview(bool isDark, bool hasUnread) {
    final preview = (widget.scheduledMessage ?? '').trim().isNotEmpty
        ? widget.scheduledMessage!.trim()
        : widget.lastMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 12.r, color: CustomColor.kPrimaryColor),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                'Scheduled for ${widget.scheduledTime ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  fontSize: 12.5.sp,
                  color: CustomColor.kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySm.copyWith(
            fontSize: 13.5.sp,
            color: hasUnread
                ? (isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary)
                : (isDark
                    ? CustomColor.kTextOnDarkMuted
                    : CustomColor.kTextSecondary),
            fontWeight: hasUnread ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageStatus(String? status) {
    switch (status) {
      case '0':
        return Icon(Icons.schedule, size: 14.r, color: CustomColor.kGoldAccent);
      case '1':
        return Icon(Icons.check, size: 14.r, color: CustomColor.kTextTertiary);
      case '2':
        return Icon(Icons.done_all,
            size: 14.r, color: CustomColor.kTextTertiary);
      case '3':
        return SentSeenIcon(isSeen: true);
      default:
        return SizedBox(width: 13.r);
    }
  }

  Widget _buildPreviewIcon(String? msgType) {
    if (msgType == null || msgType == '0') return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(right: 4.w),
      child: Icon(
        _getMediaIcon(msgType),
        size: 14.r,
        color: CustomColor.kTextSecondary,
      ),
    );
  }

  Widget _buildPreviewText(String text, bool isDark) {
    if (widget.searchQuery == null || widget.searchQuery!.isEmpty) {
      return Text(
        text,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 13.5.sp,
          color: isDark
              ? CustomColor.kTextOnDarkMuted
              : CustomColor.kTextSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final query = widget.searchQuery!.toLowerCase();
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx < 0) {
      return Text(
        text,
        style: AppTextStyles.bodySm.copyWith(
          fontSize: 13.5.sp,
          color: isDark
              ? CustomColor.kTextOnDarkMuted
              : CustomColor.kTextSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (idx > 0)
            TextSpan(
              text: text.substring(0, idx),
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 13.5.sp,
                color: isDark
                    ? CustomColor.kTextOnDarkMuted
                    : CustomColor.kTextSecondary,
              ),
            ),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: AppTextStyles.bodySm.copyWith(
              fontSize: 13.5.sp,
              color: CustomColor.kPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (idx + query.length < text.length)
            TextSpan(
              text: text.substring(idx + query.length),
              style: AppTextStyles.bodySm.copyWith(
                fontSize: 13.5.sp,
                color: isDark
                    ? CustomColor.kTextOnDarkMuted
                    : CustomColor.kTextSecondary,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = widget.newMessageCounter != '0';
    final msgType = widget.room.rLastMessage?.mMessageType;
    final isMedia = msgType != null && msgType != '0';
    final isTyping = chatController.typingUsers.contains(widget.receiverId);
    final isForwarded = widget.room.rLastMessage?.mForwarded == '1';
    final isEdited = widget.room.rLastMessage?.mIsEdited == '1';
    final isMyMessage =
        widget.room.rLastMessage?.mSenderId == userController.user?.userId;
    final hasSchedule = widget.scheduledTime != null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Slidable(
          groupTag: 'chatRoomList',
          startActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.28,
            children: [
              CustomSlidableAction(
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                onPressed: (_) {
                  if (hasUnread) {
                    homeController.makeUnreadReadMessage(widget.roomId);
                  } else {
                    widget.onToggleUnread?.call();
                  }
                  homeController.update(['update-card']);
                },
                backgroundColor: CustomColor.kPrimaryColor,
                child: Icon(
                  hasUnread
                      ? Icons.drafts_rounded
                      : Icons.mark_as_unread_rounded,
                  size: 30.sp,
                  color: CustomColor.kTextOnDark,
                ),
              ),
              CustomSlidableAction(
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                onPressed: (_) {
                  _togglePin();
                },
                backgroundColor: CustomColor.kPrimaryMedium,
                child: Icon(
                  widget.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 30.sp,
                  color: CustomColor.kTextOnDark,
                ),
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const StretchMotion(),
            extentRatio: 0.28,
            children: [
              CustomSlidableAction(
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                onPressed: (_) {
                  widget.onArchive?.call();
                },
                backgroundColor: CustomColor.kPrimaryColor,
                child: Icon(
                  widget.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 30.sp,
                  color: CustomColor.kTextOnDark,
                ),
              ),
              CustomSlidableAction(
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                onPressed: (_) => _openContextMenu(),
                backgroundColor: CustomColor.kPrimaryMedium,
                child: Icon(Icons.more_vert_rounded,
                    size: 30.sp, color: CustomColor.kTextOnDark),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: _onTap,
            onDoubleTap: _onDoubleTap,
            onLongPressStart: (details) =>
                _showChatContextMenu(details.globalPosition),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: Stack(
                children: [
                  Obx(
                    () => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      margin:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 3.h),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
                      decoration: BoxDecoration(
                        color: chatController.selectedRoomList
                                .contains(widget.roomId)
                            ? (isDark
                                ? CustomColor.kPrimaryColor
                                    .withValues(alpha: 0.08)
                                : CustomColor.kUltraLightPrimary)
                            : (isDark
                                ? CustomColor.kDarkSurface2
                                : CustomColor.kWhite),
                        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : CustomColor.kPrimaryColor
                                    .withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _Avatar(
                            isGroup: widget.isGroup,
                            profilePic: profilePic,
                            roomId: widget.roomId,
                            room: widget.room,
                            isSelected: chatController.selectedRoomList
                                .contains(widget.roomId),
                            onlineUsers: homeController.onlineUsers,
                            receiverId: widget.receiverId,
                            isScheduled: widget.isScheduled,
                            isFavorite: _isFavorite,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.name,
                                        style: (isDark
                                                ? AppTextStyles.titleMdOnDark
                                                : AppTextStyles.titleMd)
                                            .copyWith(
                                          letterSpacing: -0.3,
                                          fontWeight: hasUnread
                                              ? FontWeight.w700
                                              : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (!widget.isGroup)
                                      Padding(
                                        padding: EdgeInsets.only(left: 4.w),
                                        child: Icon(
                                          Icons.verified_rounded,
                                          size: 12.r,
                                          color: CustomColor.kPrimaryColor,
                                        ),
                                      ),
                                    if (widget.isPending)
                                      Container(
                                        margin: EdgeInsets.only(left: 4.w),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4.w, vertical: 1.h),
                                        decoration: BoxDecoration(
                                          color: CustomColor.kWarning
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.xs.r),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time_rounded,
                                                size: 10.r,
                                                color: CustomColor.kWarningText),
                                            SizedBox(width: 2.w),
                                            Text(
                                              'Pending',
                                              style:
                                                  AppTextStyles.helper.copyWith(
                                                fontSize: 9.sp,
                                                color: CustomColor.kWarningText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (widget.isMuted)
                                      Padding(
                                        padding: EdgeInsets.only(left: 4.w),
                                        child: Icon(
                                          Icons.volume_off_rounded,
                                          size: 14.r,
                                          color: CustomColor.kTextTertiary,
                                        ),
                                      ),
                                    const Spacer(),
                                    Text(
                                      widget.lastMessageTime,
                                      style: AppTextStyles.helper.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: hasUnread
                                            ? CustomColor.kPrimaryColor
                                            : (isDark
                                                ? CustomColor.kTextOnDarkMuted
                                                : CustomColor.kTextTertiary),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    if (widget.isPinned)
                                      Padding(
                                        padding: EdgeInsets.only(right: 4.w),
                                        child: Icon(
                                          Icons.push_pin_rounded,
                                          size: 14.r,
                                          color: CustomColor.kTextTertiary
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    if (isForwarded && !isTyping)
                                      Padding(
                                        padding: EdgeInsets.only(right: 4.w),
                                        child: Icon(
                                          Icons.forward_rounded,
                                          size: 14.r,
                                          color: CustomColor.kTextSecondary,
                                        ),
                                      ),
                                    if (isEdited && !isForwarded && !isTyping)
                                      Padding(
                                        padding: EdgeInsets.only(right: 4.w),
                                        child: Icon(
                                          Icons.edit_rounded,
                                          size: 14.r,
                                          color: CustomColor.kTextSecondary,
                                        ),
                                      ),
                                    if (isMedia &&
                                        !isTyping &&
                                        !isForwarded &&
                                        !isEdited)
                                      _buildPreviewIcon(msgType),
                                    if (isTyping)
                                      Padding(
                                        padding: EdgeInsets.only(right: 4.w),
                                        child: Container(
                                          width: 6.r,
                                          height: 6.r,
                                          margin: EdgeInsets.only(right: 1.w),
                                          decoration: const BoxDecoration(
                                            color: CustomColor.kOnlineGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    if (!isTyping &&
                                        widget.messageStatus != null &&
                                        widget.messageStatus!.isNotEmpty &&
                                        !widget.isGroup &&
                                        isMyMessage) ...[
                                      _buildMessageStatus(widget.messageStatus),
                                      SizedBox(width: 3.w),
                                    ],
                                    Expanded(
                                      child: isTyping
                                          ? Text(
                                              'Typing\u2026',
                                              style:
                                                  AppTextStyles.bodyMd.copyWith(
                                                color: CustomColor
                                                    .kSuccessText,
                                              ),
                                            )
                                          : (hasSchedule
                                              ? _buildScheduledPreview(
                                                  isDark, hasUnread)
                                              : (isMedia
                                                  ? Text(
                                                      _getMediaSuffix(msgType),
                                                      style: AppTextStyles
                                                          .bodySm
                                                          .copyWith(
                                                        fontSize: 13.5.sp,
                                                        color: hasUnread
                                                            ? (isDark
                                                                ? CustomColor
                                                                    .kTextOnDark
                                                                : CustomColor
                                                                    .kTextPrimary)
                                                            : (isDark
                                                                ? CustomColor
                                                                    .kTextOnDarkMuted
                                                                : CustomColor
                                                                    .kTextSecondary),
                                                        fontWeight: hasUnread
                                                            ? FontWeight.w600
                                                            : null,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )
                                                  : _buildPreviewText(
                                                      widget.lastMessage,
                                                      isDark))),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasUnread)
                                Container(
                                  constraints: BoxConstraints(
                                    minWidth: 20.r,
                                    minHeight: 20.r,
                                  ),
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 5.w),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: CustomColor.primaryGradient,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CustomColor.kPrimaryColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    widget.newMessageCounter,
                                    style: AppTextStyles.chatBadge,
                                  ),
                                ),
                              if (hasUnread) SizedBox(height: 6.h),
                              GestureDetector(
                                onTap: _openScheduleSheet,
                                child: Container(
                                  width: 28.r,
                                  height: 28.r,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: CustomColor.kPrimaryLight,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md.r),
                                  ),
                                  child: Icon(
                                    Icons.schedule_send_outlined,
                                    color: CustomColor.kPrimaryColor,
                                    size: 16.r,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showHeart)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: ScaleTransition(
                            scale: _heartAnim,
                            child: Icon(
                              Icons.favorite_rounded,
                              color: CustomColor.kDangerRed,
                              size: 48.r,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isGroup;
  final String profilePic;
  final String roomId;
  final Rooms room;
  final bool isSelected;
  final RxList<User> onlineUsers;
  final bool isScheduled;
  final bool isFavorite;
  final String receiverId;

  const _Avatar({
    required this.isGroup,
    required this.profilePic,
    required this.roomId,
    required this.room,
    required this.isSelected,
    required this.onlineUsers,
    required this.receiverId,
    this.isScheduled = false,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = room.rLastMessage?.mReadStatus == '0';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = !isGroup &&
        receiverId.isNotEmpty &&
        onlineUsers.any((u) => u.userId == receiverId);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 54.r,
          height: 54.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasUnread
                ? const LinearGradient(
                    colors: [
                      CustomColor.kPrimaryColor,
                      CustomColor.kPrimaryMedium,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : (isOnline
                    ? LinearGradient(
                        colors: [
                          CustomColor.kOnlineGreen.withValues(alpha: 0.6),
                          CustomColor.kOnlineGreen.withValues(alpha: 0.3),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          CustomColor.kPrimaryColor.withValues(alpha: 0.15),
                          CustomColor.kPrimaryMedium.withValues(alpha: 0.08),
                        ],
                      )),
          ),
          padding: EdgeInsets.all(hasUnread ? 2.5.r : 1.5.r),
          child: CircleAvatar(
            radius: 24.r,
            backgroundColor:
                isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
            backgroundImage: isGroup
                ? const AssetImage(AppAssets.defaultProfilePic)
                : (profilePic.isNotEmpty
                    ? CachedNetworkImageProvider(
                        '${Endpoints.mediaBaseUrl}$profilePic')
                    : null),
            onBackgroundImageError:
                (!isGroup && profilePic.isNotEmpty) ? (_, __) {} : null,
            child: isGroup
                ? null
                : (profilePic.isEmpty
                    ? Icon(Icons.person_rounded,
                        size: 24.r, color: CustomColor.kPrimaryColor)
                    : null),
          ),
        ),
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
                colors: [
                  CustomColor.kPrimaryColor,
                  CustomColor.kPrimaryMedium,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: CustomColor.kTextOnDark, width: 1.5),
            ),
            child: Icon(Icons.group_rounded,
                size: 10.r, color: CustomColor.kTextOnDark),
          )
        else if (isOnline)
          Container(
            width: 12.r,
            height: 12.r,
            decoration: BoxDecoration(
              color: CustomColor.kOnlineGreen,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
                width: 2,
              ),
            ),
          ),
        if (isScheduled && !isSelected && !isGroup && !isOnline)
          Positioned(
            right: 0.w,
            top: 0.h,
            child: Container(
              width: 16.r,
              height: 16.r,
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? CustomColor.kDarkSurface
                      : CustomColor.kTextOnDark,
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 8.r,
                color: CustomColor.kTextOnDark,
              ),
            ),
          ),
      ],
    );
  }
}
