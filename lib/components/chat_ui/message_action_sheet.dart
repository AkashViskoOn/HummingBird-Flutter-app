import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/chat_ui/delete_message_dialog.dart';
import 'package:humming_bird/components/chat_ui/message_info_sheet.dart';
import 'package:humming_bird/components/chat_ui/quick_forward_sheet.dart';
import 'package:humming_bird/components/chat_ui/reaction_picker.dart';
import 'package:humming_bird/components/chat_ui/reminder_options_sheet.dart';
import 'package:humming_bird/pages/chats/chat_screens/forward_message_screen.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/components/utilities/utils.dart';

class MessageActionSheet extends StatelessWidget {
  final Messages message;
  final bool isMe;
  final String roomId;
  final String receiverId;
  final String roomUsers;
  final String name;
  final String userNumber;
  final String userBio;
  final String userProfile;
  final bool isGroup;

  const MessageActionSheet({
    super.key,
    required this.message,
    required this.isMe,
    required this.roomId,
    required this.receiverId,
    required this.roomUsers,
    required this.name,
    required this.userNumber,
    required this.userBio,
    required this.userProfile,
    required this.isGroup,
  });

  static const List<String> _emojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🙏',
  ];

  static void show({
    required BuildContext context,
    required Messages message,
    required bool isMe,
    required String roomId,
    required String receiverId,
    required String roomUsers,
    required String name,
    required String userNumber,
    required String userBio,
    required String userProfile,
    required bool isGroup,
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => MessageActionSheet(
        message: message,
        isMe: isMe,
        roomId: roomId,
        receiverId: receiverId,
        roomUsers: roomUsers,
        name: name,
        userNumber: userNumber,
        userBio: userBio,
        userProfile: userProfile,
        isGroup: isGroup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final isPinned = message.mPinned == '1';
    final isStarred = message.mStarred == '1';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor =
        isDark ? CustomColor.kDarkSurface : CustomColor.kLightSurface;
    final surfaceColor =
        isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg;
    final textColor =
        isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final secondaryText =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
    final dividerColor =
        isDark ? CustomColor.kDarkDivider : CustomColor.kLightBorder;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.rounded.r),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.rounded.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.92),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).padding.bottom + AppSpacing.md.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDragHandle(
                        bgColor: bgColor, dividerColor: dividerColor),
                    _buildReactionBar(chatController, surfaceColor, isDark),
                    Divider(height: 1, color: dividerColor),
                    _buildActionMenu(
                      context,
                      chatController,
                      isPinned,
                      isStarred,
                      isDark,
                      textColor,
                      secondaryText,
                      surfaceColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle({
    required Color bgColor,
    required Color dividerColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
      child: Column(
        children: [
          Container(
            width: AppSpacing.huge.w,
            height: AppSpacing.xs.h,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(AppRadius.xxs.r),
            ),
          ),
        ],
      ),
    );
  }

  /// The emoji the CURRENT USER applied, so the quick chips can show which of
  /// the six is a toggle-remove. Parsed like `MessageReactions`; unknown → null.
  String? _myReactionEmoji(ChatController chatController) {
    final raw = message.mReactions;
    if (raw == null || raw.isEmpty) return null;
    final me = chatController.userController.userId;
    if (me.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is List && value.any((u) => u == me)) {
          return entry.key.toString();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Widget _buildReactionBar(
    ChatController chatController,
    Color surfaceColor,
    bool isDark,
  ) {
    final selectedEmoji = _myReactionEmoji(chatController);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.sm.h,
      ),
      child: SizedBox(
        height: 48.h,
        child: Row(
          children: [
            ..._emojis.map((emoji) => _buildEmojiChip(
                  chatController,
                  emoji,
                  isDark,
                  surfaceColor,
                  selected: emoji == selectedEmoji,
                )),
            SizedBox(width: AppSpacing.xs.w),
            _buildMoreReactionsButton(chatController, isDark, surfaceColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiChip(
    ChatController chatController,
    String emoji,
    bool isDark,
    Color surfaceColor, {
    bool selected = false,
  }) {
    return GestureDetector(
      onTap: () {
        chatController.toggleReaction(message.mId!, emoji);
        Navigator.pop(Get.context!);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.xs.h,
        ),
        decoration: BoxDecoration(
          color: selected
              ? CustomColor.kPrimaryColor.withValues(alpha: 0.15)
              : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
          border: Border.all(
            color: selected
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.5)
                : CustomColor.kPrimaryColor.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 22.sp),
        ),
      ),
    );
  }

  Widget _buildMoreReactionsButton(
    ChatController chatController,
    bool isDark,
    Color surfaceColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(Get.context!);
        showModalBottomSheet(
          context: Get.context!,
          useSafeArea: true,
          builder: (_) => ReactionPicker(messageId: message.mId!),
        );
      },
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
          border: Border.all(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          Icons.add_rounded,
          size: AppIcons.lg.r,
          color: CustomColor.kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildActionMenu(
    BuildContext context,
    ChatController chatController,
    bool isPinned,
    bool isStarred,
    bool isDark,
    Color textColor,
    Color secondaryText,
    Color surfaceColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionRow(context, chatController, [
            _ActionItem(
              icon: Icons.reply_rounded,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                chatController.replyToMessage(message);
              },
            ),
            _ActionItem(
              icon: Icons.forward_rounded,
              label: 'Forward',
              onTap: () {
                Navigator.pop(context);
                Get.to(() => ForwardMessageScreen(
                      messageIds: [message.mId!],
                    ));
              },
              onLongPress: () {
                Navigator.pop(context);
                QuickForwardPanel.show(context, messageIds: [message.mId!]);
              },
            ),
            _ActionItem(
              icon: Icons.content_copy_rounded,
              label: 'Copy',
              onTap: () {
                Navigator.pop(context);
                if (message.mMessage != null && message.mMessage!.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: message.mMessage!));
                  Utils.showGetSnackBar('Copied');
                }
              },
            ),
            _ActionItem(
              icon: Icons.info_outline_rounded,
              label: 'Info',
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  builder: (_) => MessageInfoSheet(messageId: message.mId!),
                );
              },
            ),
          ]),
          SizedBox(height: AppSpacing.sm.h),
          _actionRow(context, chatController, [
            _ActionItem(
              icon: isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
              label: isStarred ? 'Unstar' : 'Star',
              iconColor: isStarred ? CustomColor.kGoldAccent : null,
              onTap: () {
                Navigator.pop(context);
                if (isStarred) {
                  chatController.unstarMessage(message.mId!);
                } else {
                  chatController.starMessage(message.mId!);
                }
              },
            ),
            _ActionItem(
              icon: isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              label: isPinned ? 'Unpin' : 'Pin',
              iconColor: isPinned ? CustomColor.kPrimaryColor : null,
              onTap: () {
                Navigator.pop(context);
                if (isPinned) {
                  chatController.unpinMessage(message.mId!);
                } else {
                  chatController.pinMessage(message);
                }
              },
            ),
            _ActionItem(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                chatController.messageSelectorMap[message.mId!] = true;
                if (isMe) chatController.youMessages.add(message.mId!);
                showDialog(
                  context: context,
                  builder: (_) => const DeleteMessageDialog(),
                );
              },
            ),
            _ActionItem(
              icon: Icons.more_horiz_rounded,
              label: 'More',
              onTap: () {
                Navigator.pop(context);
                _showExtendedActions(
                    context, chatController, isStarred, isPinned);
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _actionRow(
    BuildContext context,
    ChatController chatController,
    List<_ActionItem> items,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => _buildActionChip(item)).toList(),
      ),
    );
  }

  Widget _buildActionChip(_ActionItem item) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    return GestureDetector(
      onTap: item.onTap,
      onLongPress: item.onLongPress,
      child: Container(
        constraints: BoxConstraints(minWidth: 60.w),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md.w,
          vertical: AppSpacing.sm.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: item.isDestructive
                    ? CustomColor.kDangerRed.withValues(alpha: 0.1)
                    : CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
              ),
              child: Icon(
                item.icon,
                size: AppIcons.xxl.r,
                color: item.isDestructive
                    ? CustomColor.kDangerRed
                    : item.iconColor ?? CustomColor.kPrimaryColor,
              ),
            ),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: item.isDestructive
                    ? CustomColor.kDangerRed
                    : isDark
                        ? CustomColor.kTextOnDarkSecondary
                        : CustomColor.kTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendedActions(
    BuildContext context,
    ChatController chatController,
    bool isStarred,
    bool isPinned,
  ) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.huge.w,
                height: AppSpacing.xs.h,
                decoration: BoxDecoration(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              _buildExtendedTile(
                icon: Icons.schedule_send_outlined,
                label: 'Create Schedule',
                onTap: () {
                  Navigator.pop(ctx);
                  chatController.textMessageController.text =
                      message.mMessage ?? '';
                  Get.to(() => ScheduleScreen(
                        name: name,
                        roomId: roomId,
                        receiverId: receiverId,
                        roomUsers: roomUsers,
                        messageContext: message.mId,
                      ));
                },
              ),
              _buildExtendedTile(
                icon: Icons.notifications_outlined,
                label: 'Follow Up Later',
                onTap: () {
                  Navigator.pop(ctx);
                  _showFollowUpOptions(context, chatController);
                },
              ),
              _buildExtendedTile(
                icon: Icons.alarm_rounded,
                label: 'Remind Me',
                onTap: () {
                  Navigator.pop(ctx);
                  ReminderOptionsSheet.show(
                    context,
                    message: message,
                    roomId: roomId,
                    receiverId: receiverId,
                    roomUsers: roomUsers,
                    name: name,
                    userNumber: userNumber,
                    userProfile: userProfile,
                    isGroup: isGroup,
                  );
                },
              ),
              if (isMe)
                _buildExtendedTile(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  onTap: () {
                    Navigator.pop(ctx);
                    chatController.messageSelectorMap[message.mId!] = true;
                    if (isMe) chatController.youMessages.add(message.mId!);
                    chatController.editMessageFromChatScreen();
                  },
                ),
              _buildExtendedTile(
                icon: Icons.checklist_rounded,
                label: 'Select',
                onTap: () {
                  Navigator.pop(ctx);
                  chatController.selectMessageOnLongPress(message.mId!,
                      isYouMessage: isMe);
                },
              ),
              _buildExtendedTile(
                icon: Icons.emoji_emotions_outlined,
                label: 'Add Reaction',
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    useSafeArea: true,
                    builder: (_) => ReactionPicker(messageId: message.mId!),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExtendedTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
        child: Icon(
          icon,
          color: CustomColor.kPrimaryColor,
          size: AppIcons.lg.r,
        ),
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: AppIcons.lg.r,
        color: CustomColor.kTextTertiary,
      ),
      onTap: onTap,
    );
  }

  void _showFollowUpOptions(
      BuildContext context, ChatController chatController) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.huge.w,
                height: AppSpacing.xs.h,
                decoration: BoxDecoration(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.section.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Follow Up Later',
                    style: AppTextStyles.headingMd,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              _buildExtendedTile(
                icon: Icons.access_time_rounded,
                label: 'In 1 Hour',
                onTap: () {
                  Navigator.pop(ctx);
                  _scheduleFollowUp(chatController, Duration(hours: 1));
                },
              ),
              _buildExtendedTile(
                icon: Icons.today_rounded,
                label: 'Tomorrow',
                onTap: () {
                  Navigator.pop(ctx);
                  _scheduleFollowUp(chatController, Duration(days: 1));
                },
              ),
              _buildExtendedTile(
                icon: Icons.date_range_rounded,
                label: 'Next Week',
                onTap: () {
                  Navigator.pop(ctx);
                  _scheduleFollowUp(chatController, Duration(days: 7));
                },
              ),
              _buildExtendedTile(
                icon: Icons.more_time_rounded,
                label: 'Custom',
                onTap: () {
                  Navigator.pop(ctx);
                  chatController.textMessageController.text =
                      'Follow up: ${message.mMessage ?? ''}';
                  Get.to(() => ScheduleScreen(
                        name: name,
                        roomId: roomId,
                        receiverId: receiverId,
                        roomUsers: roomUsers,
                        messageContext: message.mId,
                      ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleFollowUp(ChatController chatController, Duration duration) {
    final scheduledTime = DateTime.now().add(duration);
    chatController.pickedDate = scheduledTime;
    chatController.pickedTime = TimeOfDay.fromDateTime(scheduledTime);
    chatController.textMessageController.text =
        'Follow up: ${message.mMessage ?? ''}';
    Get.to(() => ScheduleScreen(
          name: name,
          roomId: roomId,
          receiverId: receiverId,
          roomUsers: roomUsers,
          messageContext: message.mId,
        ));
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isDestructive;
  final Color? iconColor;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.isDestructive = false,
    this.iconColor,
  });
}
