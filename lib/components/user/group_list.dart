import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/chat_ui/chat_card.dart';
import 'package:humming_bird/components/chat_ui/group_context_sheet.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/groups/group_info.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:humming_bird/services/group_system_message_service.dart';
import 'package:humming_bird/services/link_preview_service.dart';
import 'package:humming_bird/res/colors.dart';

class UserGroupsList extends StatefulWidget {
  const UserGroupsList({super.key});

  @override
  State<UserGroupsList> createState() => _UserGroupsListState();
}

class _UserGroupsListState extends State<UserGroupsList> {
  @override
  void initState() {
    contactController.fetchGroups();
    super.initState();
  }

  ContactController contactController = Get.find();
  ChatController chatController = Get.find();
  HomeController homeController = Get.find();
  GroupController groupController = Get.find();
  UserController userController = Get.find();

  bool _isGroupAdmin(Rooms group) {
    try {
      final myId = userController.storage.read('userId')?.toString();
      final admins = jsonDecode(group.rAdmins ?? '[]') as List;
      return admins.map((a) => a.toString()).contains(myId);
    } catch (_) {
      return false;
    }
  }

  void _showGroupContextMenu(Rooms group, Offset position) {
    GroupContextSheet.show(
      context: context,
      groupName:
          group.rName?.trim().isNotEmpty == true ? group.rName! : 'Group',
      groupAvatar: group.rAvatar ?? '',
      isAdmin: _isGroupAdmin(group),
      isMuted: group.rStatus == '0',
      isFavorite: homeController.isFavoriteRoom(group.rId!),
      onGroupInfo: () {
        groupController.fetchGroupInfo(group.rId!);
        Get.to(() => GroupInfo(
              groupName:
                  group.rName!.trim().isNotEmpty ? group.rName! : 'Group',
              roomId: group.rId!,
            ));
      },
      onToggleMute: () {
        group.rStatus = group.rStatus == '1' ? '0' : '1';
        LocalDatabase.saveRooms([group]);
        homeController.toggleMute(group.rId!);
        contactController.update(['group-search-update']);
      },
      onToggleFavorite: () {
        homeController.toggleFavorite(group.rId!);
        contactController.update(['group-search-update']);
      },
      onClearChat: () => _clearGroupChat(group),
      onExitGroup: () {
        final isAdmin = _isGroupAdmin(group);
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
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: CustomColor.kTextSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          onConfirm: () {
            if (isAdmin) {
              groupController.deleteGroup(group.rId!);
            } else {
              groupController.leaveGroup(group.rId!);
            }
            Get.back();
          },
        );
      },
    );
  }

  void _clearGroupChat(Rooms group) {
    Get.defaultDialog(
      title: 'Clear Chat',
      middleText: 'Delete all messages from this chat?',
      textCancel: 'Cancel',
      textConfirm: 'Clear',
      confirmTextColor: CustomColor.kTextOnDark,
      buttonColor: CustomColor.kDangerRed,
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text('Cancel',
            style: GoogleFonts.poppins(
                color: CustomColor.kTextSecondary,
                fontWeight: FontWeight.w600)),
      ),
      confirm: TextButton(
        onPressed: () {
          Get.back();
          try {
            final ids = LocalDatabase.getMessages(group.rId!)
                .map((m) => m.mId ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
            LocalDatabase.deleteMessages(ids);
            group.rLastMessage = null;
            LocalDatabase.saveRooms([group]);
            if (Get.isRegistered<ChatController>()) {
              Get.find<ChatController>()
                  .messages
                  .removeWhere((m) => m.mRoomId == group.rId);
              Get.find<ChatController>().update();
            }
          } catch (_) {}
          homeController.update(['update-card']);
        },
        child: const Text('Clear'),
      ),
    );
  }

  String _buildLastMessagePreview(Messages? message) {
    if (message == null) return '';

    // Persisted group events preview as centered system text (no sender label).
    if (GroupSystemMessageService.isSystem(message)) {
      final text = GroupSystemMessageService.preview(message);
      if (text.isNotEmpty) return text;
    }

    final type = message.mMessageType?.toString().trim() ?? '';
    final encryptedText = message.mMessage?.toString().trim() ?? '';
    final media = message.mMedia?.toString().trim() ?? '';

    String content;
    if (type == '5') {
      content = AppHelper.getMediaName(fileType: type);
    } else if (type == '0' || (encryptedText.isNotEmpty && media.isEmpty)) {
      final decrypted = _decryptPreview(encryptedText);
      content = LinkPreviewService.isLink(decrypted)
          ? LinkPreviewService.linkSummary(decrypted)
          : decrypted;
    } else {
      content = AppHelper.getMediaName(fileType: type);
    }

    final senderId = message.mSenderId ?? '';
    if (senderId.isNotEmpty) {
      final label = contactController.getGroupSenderLabel(senderId);
      if (label.isNotEmpty) return '$label: $content';
    }

    return content;
  }

  String _decryptPreview(String value) {
    if (value.isEmpty) {
      return '';
    }

    try {
      final decrypted = EncryptionHelper().decryptMessage(value);
      return decrypted.isNotEmpty ? decrypted : value;
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (_) {
        if (contactController.isFetchingContacts.value) {
          return const CustomLoading();
        } else if (contactController.groupsList.isEmpty) {
          return const AppEmptyState(
            icon: Icons.group_outlined,
            title: 'You are not in any group',
            message: 'Contacts add you to groups to get started.',
          );
        } else {
          return GetBuilder<ContactController>(
              id: 'group-search-update',
              builder: (_) {
                // Hide archived groups here — they live in Archived Chats
                final visibleGroups = contactController.groupsList
                    .where((g) =>
                        !homeController.getArchivedRoomIds().contains(g.rId))
                    .toList();
                // Pinned groups float to the top, rest keep recency order
                if (visibleGroups.length > 1) {
                  final pinnedSet = homeController.getPinnedRoomIds().toSet();
                  final originalIndex = <String, int>{
                    for (var i = 0; i < visibleGroups.length; i++)
                      visibleGroups[i].rId!: i,
                  };
                  visibleGroups.sort((a, b) {
                    final aP = pinnedSet.contains(a.rId) ? 0 : 1;
                    final bP = pinnedSet.contains(b.rId) ? 0 : 1;
                    if (aP != bP) return aP.compareTo(bP);
                    return originalIndex[a.rId!]!
                        .compareTo(originalIndex[b.rId!]!);
                  });
                }
                return ListView.builder(
                  padding: EdgeInsets.only(bottom: 92.h),
                  itemCount: visibleGroups.length,
                  itemBuilder: (context, index) {
                    Rooms group = visibleGroups[index];
                    return GetBuilder<ContactController>(
                        id: 'Update Group',
                        builder: (_) {
                          return GestureDetector(
                            onLongPressStart: (details) {
                              HapticFeedback.mediumImpact();
                              _showGroupContextMenu(
                                  group, details.globalPosition);
                            },
                            child: ChatCard(
                              name: group.rName?.trim().isNotEmpty == true
                                  ? group.rName!
                                  : 'Group',
                              receiverId: group.rId!,
                              lastMessage:
                                  _buildLastMessagePreview(group.rLastMessage),
                              roomUsers: group.rAvatar ?? '',
                              lastMessageTime:
                                  AppHelper.formatRoomsTimeFromMessage(
                                      group.rLastMessage),
                              newMessageCounter: homeController
                                  .updateUnreadMsgCounter(group.rId!),
                              roomId: group.rId!,
                              isGroup: true,
                            ),
                          );
                        });
                  },
                );
              });
        }
      },
    );
  }
}
