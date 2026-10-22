import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/home/premium_chat_tile.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_listings/archived_chats_screen.dart';
import 'package:humming_bird/pages/contacts/select_contact.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:humming_bird/services/group_system_message_service.dart';
import 'package:humming_bird/services/link_preview_service.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';

class SingleChatListing extends StatefulWidget {
  final bool showArchived;
  final RxString? selectedFilter;

  const SingleChatListing(
      {super.key, this.showArchived = false, this.selectedFilter});

  @override
  State<SingleChatListing> createState() => _SingleChatListingState();
}

class _SingleChatListingState extends State<SingleChatListing> {
  late HomeController homeController;
  late ChatController chatController;
  late ContactController contactController;
  late GroupController groupController;
  late UserController userController;
  late BirdController birdController;

  @override
  void initState() {
    homeController = Get.find();
    chatController = Get.find();
    contactController = Get.find();
    groupController = Get.put(GroupController());
    userController = Get.find();
    birdController = Get.find();
    super.initState();
  }

  String _buildLastMessage(Rooms room) {
    final last = room.rLastMessage;
    if (last == null) return '';
    // Persisted group events preview as centered system text (no sender label).
    if (GroupSystemMessageService.isSystem(last)) {
      final text = GroupSystemMessageService.preview(last);
      if (text.isNotEmpty) return text;
    }
    if (last.mStoryRef != null) {
      final decrypted = EncryptionHelper().decryptMessage(last.mMessage ?? '');
      final text = decrypted.isNotEmpty ? decrypted : (last.mMessage ?? '');
      return 'Story: $text';
    }
    if (last.mMessageType.toString() == '0') {
      final decrypted = EncryptionHelper().decryptMessage(last.mMessage ?? '');
      final text = decrypted.isNotEmpty ? decrypted : (last.mMessage ?? '');
      return LinkPreviewService.isLink(text)
          ? LinkPreviewService.linkSummary(text)
          : text;
    }
    return AppHelper.getMediaName(fileType: last.mMessageType ?? '0');
  }

  /// Sorts WhatsApp-style: pinned chats float to the top, then the most
  /// recently messaged conversations (whether sent or received) come next,
  /// oldest on down. Ties break on the original index (Dart's sort isn't
  /// stable).
  void _sortByPinnedAndRecency(List<Rooms> list, List<String> pinnedIds) {
    if (list.length < 2) return;
    final pinnedSet = pinnedIds.toSet();
    final originalIndex = <String, int>{};
    for (var i = 0; i < list.length; i++) {
      final id = list[i].rId;
      if (id != null && !originalIndex.containsKey(id)) originalIndex[id] = i;
    }
    list.sort((a, b) {
      final aPinned = pinnedSet.contains(a.rId) ? 0 : 1;
      final bPinned = pinnedSet.contains(b.rId) ? 0 : 1;
      if (aPinned != bPinned) return aPinned.compareTo(bPinned);
      final aTime = a.rLastMessage?.sentEpochSeconds ?? 0;
      final bTime = b.rLastMessage?.sentEpochSeconds ?? 0;
      if (aTime != bTime) return bTime.compareTo(aTime);
      final ai = a.rId == null ? null : originalIndex[a.rId];
      final bi = b.rId == null ? null : originalIndex[b.rId];
      if (ai != bi) return (ai ?? 0).compareTo(bi ?? 0);
      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(builder: (controller) {
      return GetBuilder<BirdController>(builder: (_) {
        // Loading skeleton disabled — show the real chat list directly.
        if (homeController.singleChatsList.isNotEmpty ||
            homeController.groupsList.isNotEmpty ||
            widget.showArchived ||
            widget.selectedFilter?.value == 'Archived') {
          return Builder(builder: (context) {
            final archivedIds = homeController.getArchivedRoomIds();
            final favoriteIds = homeController.getFavoriteRoomIds();
            final pinnedIds = homeController.getPinnedRoomIds();
            final searchQuery = homeController.searchController.text.trim();
            final myId = userController.user?.userId ?? '';

            // Pre-computed once — reused by the Archived row and branches
            final archivedSingles = homeController.singleChatsList
                .where((r) => archivedIds.contains(r.rId))
                .toList();
            final archivedGroups = homeController.groupsList
                .where((r) => archivedIds.contains(r.rId))
                .toList();
            final archivedTotal =
                archivedSingles.length + archivedGroups.length;

            final activeFilter = widget.selectedFilter?.value ?? 'All Chats';
            final isArchiveView =
                widget.showArchived || activeFilter == 'Archived';

            List<Rooms> displayList;
            if (isArchiveView) {
              displayList = [...archivedSingles, ...archivedGroups];
            } else if (activeFilter == 'Unread') {
              displayList = [
                ...homeController.singleChatsList,
                ...homeController.groupsList,
              ].where((r) {
                if (archivedIds.contains(r.rId)) return false;
                final c = homeController.updateUnreadMsgCounter(r.rId!);
                return c.isNotEmpty && int.tryParse(c) != 0;
              }).toList();
              _sortByPinnedAndRecency(displayList, pinnedIds);
            } else if (activeFilter == 'Pinned') {
              displayList = homeController.singleChatsList
                  .where((r) =>
                      !archivedIds.contains(r.rId) && pinnedIds.contains(r.rId))
                  .toList();
              _sortByPinnedAndRecency(displayList, pinnedIds);
            } else if (activeFilter == 'Favorites') {
              displayList = homeController.singleChatsList.where((r) {
                if (archivedIds.contains(r.rId)) return false;
                return favoriteIds.contains(r.rId);
              }).toList();
              _sortByPinnedAndRecency(displayList, pinnedIds);
            } else if (activeFilter == 'Mentions') {
              displayList = homeController.singleChatsList.where((r) {
                if (archivedIds.contains(r.rId)) return false;
                final mentions = r.rLastMessage?.mMentions;
                return mentions != null && mentions.contains(myId);
              }).toList();
              _sortByPinnedAndRecency(displayList, pinnedIds);
            } else if (activeFilter == 'Groups') {
              displayList = homeController.groupsList
                  .where((r) => !archivedIds.contains(r.rId))
                  .toList();
              _sortByPinnedAndRecency(displayList, pinnedIds);
            } else {
              displayList = [
                ...homeController.groupsList,
                ...homeController.singleChatsList,
              ].where((r) => !archivedIds.contains(r.rId)).toList();
              // Pinned floats to the top, then most recent activity first
              // (WhatsApp-style, whether sent or received).
              _sortByPinnedAndRecency(displayList, pinnedIds);
            }

            if (displayList.isEmpty) {
              return SizedBox(
                width: Get.width,
                height: Get.height * 0.4,
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: AppIcons.big.r,
                        height: AppIcons.big.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                              CustomColor.kPrimaryMedium
                                  .withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                        ),
                        child: Icon(
                          _emptyIcon(activeFilter),
                          color: CustomColor.kPrimaryColor,
                          size: AppIcons.xl.r,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxl.h),
                      Text(
                        _emptyTitle(activeFilter),
                        style: AppTextStyles.headingMd,
                      ),
                      SizedBox(height: AppSpacing.xs.h),
                      Text(
                        _emptySubtitle(activeFilter),
                        style: AppTextStyles.bodySm,
                      ),
                      SizedBox(height: AppSpacing.xl.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl.w,
                            vertical: AppSpacing.lg.h),
                        decoration: BoxDecoration(
                          color:
                              CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.pill.r),
                        ),
                        child: Text(
                          _emptyAction(activeFilter),
                          style: AppTextStyles.bodySm.copyWith(
                            color: CustomColor.kPrimaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final listView = SlidableAutoCloseBehavior(
              child: ListView.builder(
                padding: EdgeInsets.only(
                    bottom: 92.h + MediaQuery.of(context).padding.bottom),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  Rooms room = displayList[index];
                  final isGroupRoom = (room.rType ?? '0') == '1';
                  final (String, String, String, String) receiverData =
                      isGroupRoom
                          ? ('', '', '', '')
                          : contactController.getContactData(room);
                  final lastMsg = room.rLastMessage;
                  final favoriteIds = homeController.getFavoriteRoomIds();
                  final pinnedIds = homeController.getPinnedRoomIds();
                  final isPendingRoom = room.rIsPending == '1';
                  final nextSchedule =
                      birdController.nextScheduledForRoom(room.rId!);
                  final scheduledMessage = nextSchedule == null
                      ? null
                      : (nextSchedule.mMessage ?? '').trim().isEmpty
                          ? null
                          : nextSchedule.mMessage!.trim();
                  final scheduledTime = nextSchedule == null
                      ? null
                      : AppHelper.formatDateTimeFromEpoch(
                          nextSchedule.mScheduledAt ?? '', 'h:mm a');
                  return RepaintBoundary(
                    child: Entrance(
                      delayFactor: (index % 8) * 0.05,
                      child: PremiumChatTile(
                        room: room,
                        name: isGroupRoom
                            ? (room.rName?.trim().isNotEmpty == true
                                ? room.rName!
                                : 'Group')
                            : (receiverData.$1.isNotEmpty
                                ? receiverData.$1
                                : room.rAdminNumber.toString()),
                        receiverId: isGroupRoom ? room.rId! : receiverData.$2,
                        isGroup: isGroupRoom,
                        lastMessage: _buildLastMessage(room),
                        lastMessageTime:
                            AppHelper.formatRoomsTimeFromMessage(lastMsg),
                        newMessageCounter:
                            homeController.updateUnreadMsgCounter(room.rId!),
                        roomId: room.rId!,
                        userNumber: receiverData.$3,
                        userBio: receiverData.$4,
                        isPinned: pinnedIds.contains(room.rId),
                        isMuted: room.rStatus == '0',
                        isScheduled: lastMsg?.mIsScheduled == '1',
                        scheduledTime: scheduledTime,
                        scheduledMessage: scheduledMessage,
                        isFavorite: favoriteIds.contains(room.rId),
                        isArchived: archivedIds.contains(room.rId),
                        messageStatus: lastMsg?.mReadStatus,
                        searchQuery:
                            searchQuery.isNotEmpty ? searchQuery : null,
                        onArchive: () =>
                            homeController.toggleArchive(room.rId!),
                        onToggleUnread: () =>
                            homeController.markAsUnread(room.rId!),
                        isPending: isPendingRoom,
                        isSelected:
                            chatController.selectedRoomList.contains(room.rId!),
                        onSelect: () =>
                            chatController.manageRoomSelector(room.rId!),
                      ),
                    ),
                  );
                },
              ),
            );

            // WhatsApp-style compact Archived row — only on the main
            // "All Chats" view, only when something is actually archived.
            if (!isArchiveView &&
                activeFilter == 'All Chats' &&
                archivedTotal > 0) {
              return Column(
                children: [
                  _ArchivedRow(count: archivedTotal),
                  Expanded(child: listView),
                ],
              );
            }
            return listView;
          });
        } else {
          return SizedBox(
            width: Get.width,
            height: Get.height * 0.4,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: AppIcons.big.r,
                    height: AppIcons.big.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                          CustomColor.kPrimaryMedium.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: CustomColor.kPrimaryColor,
                      size: AppIcons.xl.r,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl.h),
                  Text("No chats yet", style: AppTextStyles.headingMd),
                  SizedBox(height: AppSpacing.xs.h),
                  Text("Start a new conversation", style: AppTextStyles.bodySm),
                  SizedBox(height: AppSpacing.xl.h),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Get.to(() => const AllContactsScreen()),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl.w,
                          vertical: AppSpacing.lg.h),
                      decoration: BoxDecoration(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.pill.r),
                      ),
                      child: Text(
                        'Tap + to start messaging',
                        style: AppTextStyles.bodySm.copyWith(
                          color: CustomColor.kPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });
    });
  }

  IconData _emptyIcon(String filter) {
    switch (filter) {
      case 'Archived':
        return Icons.archive_rounded;
      case 'Unread':
        return Icons.mark_as_unread_rounded;
      case 'Pinned':
        return Icons.push_pin_rounded;
      case 'Favorites':
        return Icons.star_rounded;
      case 'Mentions':
        return Icons.alternate_email_rounded;
      case 'Groups':
        return Icons.groups_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  String _emptyTitle(String filter) {
    switch (filter) {
      case 'Archived':
        return 'No archived chats';
      case 'Unread':
        return 'No unread chats';
      case 'Pinned':
        return 'No pinned chats';
      case 'Favorites':
        return 'No favorite chats';
      case 'Mentions':
        return 'No mentions';
      case 'Groups':
        return 'No group chats';
      default:
        return 'No chats yet';
    }
  }

  String _emptySubtitle(String filter) {
    switch (filter) {
      case 'Archived':
        return 'Archived chats will appear here';
      case 'Mentions':
        return 'Messages mentioning you will appear here';
      case 'Groups':
        return 'Create a group to start a group conversation';
      case 'Pinned':
        return 'Pin a chat to see it here';
      case 'Favorites':
        return 'Mark chats as favorite to see them here';
      default:
        return 'Start a new conversation';
    }
  }

  String _emptyAction(String filter) {
    return 'Tap + to start messaging';
  }
}

/// Compact WhatsApp-style row shown at the top of the main chat list that
/// opens the Archived Chats screen. Uses only existing theme colors.
class _ArchivedRow extends StatelessWidget {
  final int count;
  const _ArchivedRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Entrance(
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 6.h),
        child: Material(
          color:
              isDark ? CustomColor.kDarkSurface2 : CustomColor.kCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
            onTap: () => Get.to(() => const ArchivedChatsScreen()),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              child: Row(
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md.r),
                    ),
                    child: Icon(
                      Icons.archive_rounded,
                      color: CustomColor.kPrimaryColor,
                      size: AppIcons.sm.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Archived',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary,
                      ),
                    ),
                  ),
                  if (count > 0)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.pill.r),
                      ),
                      child: Text(
                        '$count',
                        style: AppTextStyles.labelSm.copyWith(
                          color: CustomColor.kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? CustomColor.kTextOnDarkMuted
                        : CustomColor.kTextTertiary,
                    size: AppIcons.sm.r,
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
