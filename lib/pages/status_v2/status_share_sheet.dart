import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/message_api.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/status_v2/widgets/status_ring_avatar.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Sheet to share/forward a status as a chat message.
class StatusShareSheet extends StatefulWidget {
  final StatusModel status;

  const StatusShareSheet({super.key, required this.status});

  @override
  State<StatusShareSheet> createState() => _StatusShareSheetState();
}

class _StatusShareSheetState extends State<StatusShareSheet> {
  late HomeController _home;
  late ContactController _contact;

  @override
  void initState() {
    super.initState();
    _home = Get.find<HomeController>();
    _contact = Get.find<ContactController>();
  }

  String _otherUserId(Rooms room) {
    try {
      final ids = jsonDecode(room.rUsers ?? '[]') as List;
      final myId = Get.find<UserController>().user?.userId?.toString();
      return ids
          .firstWhere((id) => id.toString() != myId, orElse: () => '')
          .toString();
    } catch (_) {
      return '';
    }
  }

  String _roomName(Rooms room) {
    if (room.rType == '1') return room.rName ?? 'Group';
    final name = _contact.getUserNameById(_otherUserId(room));
    if (name.isNotEmpty) return name;
    return room.rName ?? 'Chat';
  }

  String _roomAvatar(Rooms room) {
    if (room.rType == '1') return room.rAvatar ?? '';
    return _contact.getUserProfilePic(_otherUserId(room));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rooms = <Rooms>[
        ..._home.singleChatsList,
        ..._home.groupsList,
      ];
      return Container(
        constraints: BoxConstraints(maxHeight: 0.7.sh),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: CustomColor.kLightBorder,
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text('Forward to', style: AppTextStyles.headingSm),
              SizedBox(height: 12.h),
              if (rooms.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: AppEmptyState(
                    icon: Icons.forward_to_inbox_rounded,
                    title: 'No chats to forward to',
                    message: 'Start a chat first to forward statuses',
                    layout: EmptyStateLayout.inline,
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (ctx, i) {
                      final room = rooms[i];
                      final avatar = _roomAvatar(room);
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                        leading: StatusRingAvatar(
                          imageUrl: avatar.isNotEmpty ? avatar : null,
                          size: 44,
                          alwaysColorRing: true,
                        ),
                        title: Text(
                          _roomName(room),
                          style: AppTextStyles.titleSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _forward(room),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _forward(Rooms room) async {
    final status = widget.status;
    final statusId = status.suId;
    final statusCtrl = Get.find<StatusController>();
    if (statusId != null) {
      await statusCtrl.shareStatus(statusId);
    }

    final myId = Get.find<UserController>().user?.userId?.toString();
    final isGroup = room.rType == '1';
    final receiverId = isGroup ? '' : _otherUserId(room);
    if (myId == null) {
      Get.back();
      return;
    }

    // Replicate the status as a chat message (falls back to text-content message).
    try {
      final mediaType = status.suMediaType;
      final isMedia = mediaType == 'image' || mediaType == 'video';
      final messageBody = isMedia
          ? status.suCaption?.isNotEmpty == true
              ? status.suCaption!
              : 'Status'
          : (status.suContent ?? 'Status');
      final messageData = <String, dynamic>{
        'm_room_id': room.rId?.toString(),
        'm_message_type': '0',
        'm_message': EncryptionHelper().encryptMessage(messageBody),
        'm_sender_id': myId,
        'm_is_scheduled': '0',
        'm_scheduled_at': '0',
        'm_replied_on': '',
        'me': true,
        'receiver_id': receiverId,
        'm_read_status': '0',
        'm_interval': '0',
        'm_count': 1,
      };
      if (statusId != null) {
        messageData['m_story_ref'] = jsonEncode({
          'story_id': statusId,
          'story_owner_id': myId,
          'story_owner_name': 'My Status',
          'reply_type': 'forward',
          'message': messageBody,
          'reaction': '',
          'media_url': status.suMediaUrl ?? '',
          'media_type': status.suMediaType ?? 'text',
          'content': status.suContent ?? '',
          'caption': status.suCaption ?? '',
          'bg_color': status.suBgColor ?? '',
          'text_color': status.suTextColor ?? '',
          'created_at': status.suCreatedAt ?? '',
        });
      }
      final res = await MessageApi().sendMessage(messageData);
      final model = res?.msg;
      if (res?.status == true && model != null) {
        if (kDebugMode) {
          debugPrint('STATUS-REPLY-TRACE → forwarded with '
              'storyRef=${model.mStoryRef}');
        }
        Get.find<ChatController>().socket.emit('message', model.toJson());
        Get.find<ChatController>().addSentMessage(model);
      }
    } catch (_) {}
    if (mounted) Get.back();
    CustomSnackbar.success(
        title: 'Forwarded', message: 'Status shared with ${_roomName(room)}');
  }
}
