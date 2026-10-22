import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/chat_ui/ai_message_bottom_sheet.dart';
import 'package:humming_bird/components/chat_ui/block_user_dialog.dart';
import 'package:humming_bird/components/chat_ui/report_dialog.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/Schedule_Pages/chat_schedule_calendar_page.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_message_search_page.dart';
import 'package:humming_bird/pages/chats/chat_screens/pinned_messages_page.dart';
import 'package:humming_bird/pages/groups/group_info.dart';
import 'package:humming_bird/pages/groups/message_info.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class PremiumChatMenu extends StatelessWidget {
  final String userName;
  final String userNumber;
  final String roomId;
  final String receiverId;
  final bool isGroup;

  const PremiumChatMenu({
    super.key,
    required this.userName,
    required this.userNumber,
    required this.roomId,
    required this.receiverId,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton(
      position: PopupMenuPosition.under,
      offset: Offset(0, 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
      ),
      elevation: 0,
      color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      itemBuilder: (_) => _buildItems(context, isDark),
      child: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: CustomColor.kTextOnDark.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(
            color: CustomColor.kOverlay8,
          ),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          size: AppIcons.xl.r,
          color: CustomColor.kTextOnDark,
        ),
      ),
    );
  }

  List<PopupMenuEntry> _buildItems(BuildContext context, bool isDark) {
    final chatController = Get.find<ChatController>();
    final items = <PopupMenuEntry>[];

    if (isGroup) {
      final groupController = Get.find<GroupController>();
      final homeController = Get.find<HomeController>();
      final groupName = _safeGroupName(groupController, roomId);
      final group = _findGroup(groupController, roomId);
      final isGroupMuted = group?.rStatus == '0';

      _addItem(
        items,
        Icons.search_rounded,
        'Search messages',
        isDark,
        () => Future.microtask(() =>
            Get.to(() => const ChatMessageSearchPage(title: 'Group chat'))),
      );

      _addItem(
        items,
        Icons.event_rounded,
        'Create Group Event',
        isDark,
        () {
          chatController.textMessageController.text = 'Group Event: ';
          chatController.scheduleOn = true;
          Get.to(() => ScheduleScreen(
                name: groupName,
                roomId: roomId,
                receiverId: '',
                roomUsers: '',
                forGroup: true,
              ));
        },
      );

      if (chatController.messageSelectorMap.length == 1 &&
          chatController.youMessages.isEmpty) {
        _addItem(
          items,
          Icons.info_outline_rounded,
          'Info',
          isDark,
          () => showMessageInfoSheet(
              chatController.messageSelectorMap.keys.toList()[0]),
        );
      }

      items.add(_buildDivider(isDark));

      _addItem(
        items,
        Icons.calendar_month_rounded,
        'Scheduled Messages',
        isDark,
        () => Get.to(() => ChatScheduleCalendarPage(
              roomId: roomId,
              title: groupName,
            )),
      );

      _addItem(
        items,
        Icons.push_pin_rounded,
        'Pinned Messages',
        isDark,
        () => Get.to(() => PinnedMessagesPage(roomId: roomId)),
      );

      _addItem(
        items,
        isGroupMuted
            ? Icons.notifications_rounded
            : Icons.notifications_off_outlined,
        isGroupMuted ? 'Unmute Notifications' : 'Mute Notifications',
        isDark,
        () {
          if (group == null) return;
          group.rStatus = group.rStatus == '1' ? '0' : '1';
          LocalDatabase.saveRooms([group]);
          homeController.toggleMute(roomId);
        },
      );

      _addItem(
        items,
        Icons.info_outline_rounded,
        'Group Info',
        isDark,
        () {
          groupController.fetchGroupInfo(roomId);
          Get.to(() => GroupInfo(
                groupName: groupName,
                roomId: roomId,
              ));
        },
      );

      items.add(_buildDivider(isDark));

      _addItem(
        items,
        Icons.auto_awesome_rounded,
        'AI Assist',
        isDark,
        () => showModalBottomSheet(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (_) => const AiMessageBottomSheet(),
        ),
      );

      _addItem(
        items,
        Icons.summarize_rounded,
        'Summarize',
        isDark,
        () => _showSummarize(context, chatController),
      );
    } else {
      final contactController = Get.find<ContactController>();
      final userid = contactController.getUserIdByNumber(userNumber);
      final isBlocked = contactController.checkIfUserIsBlocked(userid);

      _addItem(
        items,
        Icons.search_rounded,
        'Search messages',
        isDark,
        () => Future.microtask(
            () => Get.to(() => ChatMessageSearchPage(title: userName))),
      );

      if (chatController.canEditSelectedMessage) {
        _addItem(
          items,
          Icons.edit_rounded,
          'Edit Message',
          isDark,
          () => chatController.editMessageFromChatScreen(),
        );
      }

      _addItem(
        items,
        Icons.calendar_month_rounded,
        'Scheduled Messages',
        isDark,
        () => Get.to(() => ChatScheduleCalendarPage(
              roomId: roomId,
              title: userName,
            )),
      );

      _addItem(
        items,
        Icons.push_pin_rounded,
        'Pinned Messages',
        isDark,
        () => Get.to(() => PinnedMessagesPage(roomId: roomId)),
      );

      items.add(_buildDivider(isDark));

      _addItem(
        items,
        Icons.auto_awesome_rounded,
        'AI Assist',
        isDark,
        () => showModalBottomSheet(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (_) => const AiMessageBottomSheet(),
        ),
      );

      _addItem(
        items,
        isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
        isBlocked
            ? 'Unblock ${userName.split(' ')[0]}'
            : 'Block ${userName.split(' ')[0]}',
        isDark,
        () => showDialog(
          context: context,
          builder: (context) => BlockUserDialog(
            userId: contactController.getUserIdByNumber(userNumber),
            userName: userName.split(' ')[0],
          ),
        ),
      );

      _addItem(
        items,
        Icons.report_rounded,
        'Report ${userName.split(' ')[0]}',
        isDark,
        () => showDialog(
          context: context,
          builder: (context) => ReportDialog(
            userId: contactController.getUserIdByNumber(userNumber),
            userName: userName.split(' ')[0],
          ),
        ),
        isDanger: true,
      );
    }

    return items;
  }

  void _showSummarize(BuildContext context, ChatController chatController) {
    chatController.generateSummary();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.rounded.r),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.section.w, AppSpacing.xl.h,
              AppSpacing.section.w, AppSpacing.section.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: AppSpacing.xs.h,
                margin: EdgeInsets.only(bottom: AppSpacing.xxl.h),
                decoration: BoxDecoration(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md.r),
                    decoration: BoxDecoration(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.lg.r),
                    ),
                    child: Icon(Icons.summarize_rounded,
                        color: CustomColor.kPrimaryColor, size: AppIcons.lg.r),
                  ),
                  SizedBox(width: AppSpacing.xl.w),
                  Text(
                    'Conversation Summary',
                    style: AppTextStyles.headingMd
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xxl.h),
              Obx(() {
                if (chatController.isGeneratingSummary.value) {
                  return Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: AppSpacing.section.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: AppIcons.md.r,
                          height: AppIcons.md.r,
                          child: const CircularProgressIndicator.adaptive(
                              strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.lg.w),
                        Text(
                          'Generating summary...',
                          style: AppTextStyles.chatPreview,
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  padding: EdgeInsets.all(AppSpacing.xxl.r),
                  decoration: BoxDecoration(
                    color: CustomColor.kUltraLightPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    border: Border.all(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    chatController.conversationSummary.value.isNotEmpty
                        ? chatController.conversationSummary.value
                        : 'Summary will appear here after generation.',
                    style: AppTextStyles.chatPreview.copyWith(height: 1.5),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _safeGroupName(GroupController gc, String rid) {
    try {
      return gc.getUpdatedGroup(rid).rName ?? 'Group';
    } catch (_) {
      return 'Group';
    }
  }

  Rooms? _findGroup(GroupController gc, String rid) {
    try {
      return gc.getUpdatedGroup(rid);
    } catch (_) {}
    try {
      return Get.find<HomeController>()
          .groupsList
          .firstWhere((g) => g.rId == rid);
    } catch (_) {
      return null;
    }
  }

  PopupMenuDivider _buildDivider(bool isDark) {
    return PopupMenuDivider(
      height: 1,
    );
  }

  void _addItem(
    List<PopupMenuEntry> items,
    IconData icon,
    String text,
    bool isDark,
    VoidCallback? onTap, {
    bool isDanger = false,
  }) {
    items.add(PopupMenuItem(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl.w),
      onTap: onTap,
      child: _PremiumMenuItemRow(
        icon: icon,
        text: text,
        isDanger: isDanger,
        isDark: isDark,
      ),
    ));
  }
}

class _PremiumMenuItemRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDanger;
  final bool isDark;

  const _PremiumMenuItemRow({
    required this.icon,
    required this.text,
    this.isDanger = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDanger
        ? CustomColor.kDangerRed
        : (isDark
            ? CustomColor.kTextOnDarkSecondary
            : CustomColor.kTextSecondary);
    final textColor = isDanger
        ? CustomColor.kDangerRed
        : (isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary);

    return Row(
      children: [
        SizedBox(
          width: 24.r,
          child: Icon(icon, size: AppIcons.lg.r, color: iconColor),
        ),
        SizedBox(width: AppSpacing.xl.w),
        Text(
          text,
          style: AppTextStyles.bodyMd.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
