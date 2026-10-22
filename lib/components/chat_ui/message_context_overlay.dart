import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/chat_ui/delete_message_dialog.dart';
import 'package:humming_bird/components/chat_ui/message_info_sheet.dart';
import 'package:humming_bird/components/chat_ui/quick_forward_sheet.dart';
import 'package:humming_bird/components/chat_ui/reminder_options_sheet.dart';
import 'package:humming_bird/pages/chats/chat_screens/forward_message_screen.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_screen.dart';
import 'package:humming_bird/pages/scheduled_moments/schedule_moment_sheet.dart';
import 'package:humming_bird/services/link_preview_service.dart';

class MessageContextOverlay {
  MessageContextOverlay._();

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

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
    required Offset messageGlobalPosition,
    required Size messageSize,
  }) {
    dismiss();

    final overlay = Overlay.of(context);

    _entry = OverlayEntry(
      builder: (_) => _OverlayWidget(
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
        messageGlobalPosition: messageGlobalPosition,
        messageSize: messageSize,
      ),
    );

    overlay.insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _OverlayWidget extends StatefulWidget {
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
  final Offset messageGlobalPosition;
  final Size messageSize;

  const _OverlayWidget({
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
    required this.messageGlobalPosition,
    required this.messageSize,
  });

  @override
  State<_OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<_OverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  final ChatController _chatController = Get.find();
  late String _messageId;

  /// The emoji the CURRENT USER applied (one reaction per user per message),
  /// so the quick bar can show which of the six is a toggle-remove. Parsed the
  /// same way `MessageReactions` parses `mReactions`; unknown → null (no mark).
  String? get _myReactionEmoji {
    final raw = widget.message.mReactions;
    if (raw == null || raw.isEmpty) return null;
    final me = _chatController.userController.userId;
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

  bool _showMore = false;

  @override
  void initState() {
    super.initState();
    _messageId = widget.message.mId ?? '';
    HapticFeedback.mediumImpact();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller
      ..duration = const Duration(milliseconds: 150)
      ..reverse().then((_) {
        if (mounted) MessageContextOverlay.dismiss();
      });
  }

  void _dismissImmediately() {
    _controller.stop();
    MessageContextOverlay.dismiss();
  }

  void _onReactionTap(String emoji) {
    if (emoji == '+') {
      _dismissImmediately();
      _showEmojiPicker();
      return;
    }
    _chatController.toggleReaction(_messageId, emoji);
    _dismiss();
  }

  void _showEmojiPicker() {
    final ctx = Get.context!;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FullEmojiPickerSheet(
        messageId: _messageId,
      ),
    );
  }

  void _onReply() {
    _chatController.replyToMessage(widget.message);
    _dismiss();
  }

  void _onSelect() {
    _dismiss();
    _chatController.messageSelectorMap[widget.message.mId!] = true;
    _chatController.isMultiSelectMode.value = true;
  }

  void _onForward() {
    _dismissImmediately();
    Get.to(() => ForwardMessageScreen(messageIds: [_messageId]));
  }

  void _onForwardLongPress() {
    _dismissImmediately();
    QuickForwardPanel.show(context, messageIds: [_messageId]);
  }

  void _onRemind() {
    _dismiss();
    ReminderOptionsSheet.show(
      context,
      message: widget.message,
      roomId: widget.roomId,
      receiverId: widget.receiverId,
      roomUsers: widget.roomUsers,
      name: widget.name,
      userNumber: widget.userNumber,
      userProfile: widget.userProfile,
      isGroup: widget.isGroup,
    );
  }

  void _onCopy() async {
    final text = widget.message.mMessage ?? '';
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
      Utils.showGetSnackBar('Copied to clipboard');
    }
    _dismiss();
  }

  void _onCopyLink() async {
    final url = _linkUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    Utils.showGetSnackBar('Link copied');
    _dismiss();
  }

  void _onOpenLink() {
    final url = _linkUrl;
    if (url == null) return;
    _dismiss();
    LinkOpener.open(url);
  }

  String? get _linkUrl =>
      LinkPreviewService.detectFirstUrl(widget.message.mMessage);

  void _onInfo() {
    final ctx = Get.context!;
    _dismissImmediately();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      builder: (_) => MessageInfoSheet(messageId: _messageId),
    );
  }

  void _onStar() {
    final isStarred = widget.message.mStarred == '1';
    if (isStarred) {
      _chatController.unstarMessage(_messageId);
    } else {
      _chatController.starMessage(_messageId);
    }
    _dismiss();
  }

  void _onDelete() {
    final ctx = Get.context!;
    _dismissImmediately();
    _chatController.messageSelectorMap.value = {widget.message.mId!: true};
    if (widget.isMe) {
      _chatController.youMessages.add(widget.message.mId!);
    }
    showDialog(
      context: ctx,
      builder: (_) => const DeleteMessageDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final topSafe = MediaQuery.of(context).padding.top;

    final msgTop = widget.messageGlobalPosition.dy;
    final msgBottom = msgTop + widget.messageSize.height;
    final msgCenterX =
        widget.messageGlobalPosition.dx + widget.messageSize.width / 2;

    final emojiBarHeight = 56.h;
    final emojiBarWidth = 380.w;
    final gap = 10.h;
    final cardHSpacing = 16.h;
    final cardItemH = 46.h;
    final cardPadV = 8.h;
    final int itemCount = 7;
    final double menuHeight =
        itemCount * cardItemH + cardPadV * 2 + cardHSpacing;

    final spaceBelow = screenSize.height - msgBottom - bottomSafe;
    final spaceAbove = msgTop - topSafe;

    final double menuTop;
    final double emojiTop;

    final bool menuBelow = spaceBelow >= menuHeight + gap;
    if (menuBelow) {
      emojiTop = msgTop - emojiBarHeight - gap;
      menuTop = msgBottom + gap;
    } else if (spaceAbove >= menuHeight + emojiBarHeight + gap * 2) {
      menuTop = msgTop - gap - emojiBarHeight - gap - menuHeight;
      emojiTop = msgTop - emojiBarHeight - gap;
    } else {
      emojiTop = (msgTop - emojiBarHeight - gap).clamp(
          topSafe + 4, screenSize.height - emojiBarHeight - bottomSafe - 4);
      menuTop = (emojiTop + emojiBarHeight + gap)
          .clamp(topSafe + 4, screenSize.height - menuHeight - bottomSafe - 4);
    }

    final clampedEmojiTop = emojiTop.clamp(
        topSafe + 4, screenSize.height - emojiBarHeight - bottomSafe - 4);
    final clampedMenuTop = menuTop.clamp(
        topSafe + 4, screenSize.height - menuHeight - bottomSafe - 4);

    final emojiLeft = (msgCenterX - emojiBarWidth / 2)
        .clamp(8.0, screenSize.width - emojiBarWidth - 8.0);
    final menuLeft =
        (msgCenterX - 180.w / 2).clamp(8.w, screenSize.width - 180.w - 8.w);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _dismiss,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                color: Colors.black.withValues(alpha: 0.2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          if (_showMore)
            Positioned(
              top: clampedMenuTop,
              left: menuLeft,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: _MoreMenu(
                    message: widget.message,
                    isMe: widget.isMe,
                    onSelect: () {
                      setState(() {
                        _chatController.selectMessageOnLongPress(_messageId,
                            isYouMessage: widget.isMe);
                      });
                      _dismiss();
                    },
                    onEdit: widget.isMe
                        ? () {
                            _dismiss();
                            _chatController.editMessageFromChatScreen(
                                message: widget.message);
                          }
                        : null,
                    onSchedule: () {
                      _dismiss();
                      Get.to(() => ScheduleScreen(
                            name: widget.name,
                            roomId: widget.roomId,
                            receiverId: widget.receiverId,
                            roomUsers: widget.roomUsers,
                            forGroup: widget.isGroup,
                            messageContext: widget.message.mMessage,
                          ));
                    },
                    onRemind: _onRemind,
                    onMoment: () {
                      _dismiss();
                      final msgType =
                          int.tryParse(widget.message.mMessageType ?? '0') ?? 0;
                      String mediaType = 'text';
                      if (msgType == 1) {
                        mediaType = 'image';
                      } else if (msgType == 2) {
                        mediaType = 'video';
                      } else if (msgType == 3) {
                        mediaType = 'document';
                      }
                      Get.bottomSheet(
                        ScheduleMomentSheet(
                          content: widget.message.mMessage ?? '',
                          mediaType: mediaType,
                        ),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                      );
                    },
                    // onAddReaction: () {
                    //   final ctx = Get.context!;
                    //   _dismissImmediately();
                    //   showModalBottomSheet(
                    //     context: ctx,
                    //     isScrollControlled: true,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.vertical(
                    //           top: Radius.circular(AppRadius.xxl.r)),
                    //     ),
                    //     builder: (_) => _FullEmojiPickerSheet(
                    //       messageId: _messageId,
                    //     ),
                    //   );
                    // },
                  ),
                ),
              ),
            )
          else ...[
            Positioned(
              top: clampedEmojiTop,
              left: emojiLeft,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: _EmojiBar(
                    onEmojiTap: _onReactionTap,
                    selectedEmoji: _myReactionEmoji,
                  ),
                ),
              ),
            ),
            Positioned(
              top: clampedMenuTop,
              left: menuLeft,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: _MenuCard(
                    message: widget.message,
                    isMe: widget.isMe,
                    onReply: _onReply,
                    onSelect: _onSelect,
                    onForward: _onForward,
                    onForwardLongPress: _onForwardLongPress,
                    onCopy: _onCopy,
                    onCopyLink: _onCopyLink,
                    onOpenLink: _onOpenLink,
                    isLink: _linkUrl != null,
                    onInfo: _onInfo,
                    onStar: _onStar,
                    onDelete: _onDelete,
                    onMore: () => setState(() => _showMore = true),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmojiBar extends StatelessWidget {
  final void Function(String emoji) onEmojiTap;
  final String? selectedEmoji;

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  const _EmojiBar({required this.onEmojiTap, this.selectedEmoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.rounded.r),
        boxShadow: AppShadow.elevatedLight,
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._emojis.map((emoji) {
            final selected = emoji == selectedEmoji;
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
              onTap: () => onEmojiTap(emoji),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                decoration: selected
                    ? BoxDecoration(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.14),
                        borderRadius:
                            BorderRadius.circular(AppRadius.eighteen.r),
                      )
                    : null,
                child: Text(emoji, style: TextStyle(fontSize: 28.sp)),
              ),
            );
          }),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
            onTap: () => onEmojiTap('+'),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              child: Icon(Icons.add_rounded,
                  size: 24.r, color: CustomColor.kTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Messages message;
  final bool isMe;
  final VoidCallback onReply;
  final VoidCallback onSelect;
  final VoidCallback onForward;
  final VoidCallback onForwardLongPress;
  final VoidCallback onCopy;
  final VoidCallback onCopyLink;
  final VoidCallback onOpenLink;
  final bool isLink;
  final VoidCallback onInfo;
  final VoidCallback onStar;
  final VoidCallback onDelete;
  final VoidCallback onMore;

  const _MenuCard({
    required this.message,
    required this.isMe,
    required this.onReply,
    required this.onSelect,
    required this.onForward,
    required this.onForwardLongPress,
    required this.onCopy,
    required this.onCopyLink,
    required this.onOpenLink,
    required this.isLink,
    required this.onInfo,
    required this.onStar,
    required this.onDelete,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final isStarred = message.mStarred == '1';
    return Container(
      width: 180.w,
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        boxShadow: AppShadow.elevatedLight,
      ),
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuItem(
            icon: Icons.reply_rounded,
            label: 'Reply',
            onTap: onReply,
          ),
          _MenuItem(
            icon: Icons.check_circle_outline_rounded,
            label: 'Select',
            onTap: onSelect,
          ),
          _MenuItem(
            icon: Icons.forward_rounded,
            label: 'Forward',
            onTap: onForward,
            onLongPress: onForwardLongPress,
          ),
          _MenuItem(
            icon: Icons.content_copy_rounded,
            label: 'Copy',
            onTap: onCopy,
          ),
          if (isLink) ...[
            _MenuItem(
              icon: Icons.open_in_new_rounded,
              label: 'Open Link',
              onTap: onOpenLink,
            ),
            _MenuItem(
              icon: Icons.link_rounded,
              label: 'Copy Link',
              onTap: onCopyLink,
            ),
          ],
          _MenuItem(
            icon: Icons.info_outline_rounded,
            label: 'Info',
            onTap: onInfo,
          ),
          _MenuItem(
            icon: isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
            label: isStarred ? 'Unstar' : 'Star',
            onTap: onStar,
          ),
          const Divider(height: 1, thickness: 0.5, indent: 14, endIndent: 14),
          _MenuItem(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            isDestructive: true,
            onTap: onDelete,
          ),
          _MenuItem(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20.r,
                color: isDestructive
                    ? CustomColor.kDangerRed
                    : CustomColor.kTextSecondary,
              ),
              SizedBox(width: 14.w),
              Text(
                label,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDestructive
                      ? CustomColor.kDangerRed
                      : CustomColor.kTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final Messages message;
  final bool isMe;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final VoidCallback onSchedule;
  final VoidCallback onMoment;
  final VoidCallback onRemind;

  const _MoreMenu({
    required this.message,
    required this.isMe,
    required this.onSelect,
    required this.onEdit,
    required this.onSchedule,
    required this.onMoment,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.w,
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        boxShadow: AppShadow.elevatedLight,
      ),
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuItem(
            icon: Icons.calendar_today_rounded,
            label: 'Create Schedule',
            onTap: onSchedule,
          ),
          _MenuItem(
            icon: Icons.alarm_rounded,
            label: 'Remind Me',
            onTap: onRemind,
          ),
          _MenuItem(
            icon: Icons.movie_creation_outlined,
            label: 'Create Moment',
            onTap: onMoment,
          ),
          _MenuItem(
            icon: Icons.checklist_rounded,
            label: 'Select',
            onTap: onSelect,
          ),
          if (onEdit != null)
            _MenuItem(
              icon: Icons.edit_rounded,
              label: 'Edit',
              onTap: onEdit!,
            ),
        ],
      ),
    );
  }
}

class _FullEmojiPickerSheet extends StatelessWidget {
  final String messageId;

  const _FullEmojiPickerSheet({required this.messageId});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    return Container(
      height: 350.h,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl.r)),
        boxShadow: AppShadow.cardLight,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 4.h),
            child: Container(
              width: 32.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.xxs.r),
              ),
            ),
          ),
          Expanded(
            child: EmojiPicker(
              textEditingController: TextEditingController(),
              config: Config(
                height: 300.h,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  buttonMode: ButtonMode.MATERIAL,
                  emojiSizeMax: 28 * 1.0,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: const CategoryViewConfig(),
                bottomActionBarConfig: const BottomActionBarConfig(
                  showSearchViewButton: false,
                ),
                searchViewConfig: const SearchViewConfig(),
              ),
              onEmojiSelected: (category, emoji) {
                chatController.toggleReaction(messageId, emoji.emoji);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
