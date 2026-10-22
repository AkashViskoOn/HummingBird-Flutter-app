import 'dart:convert';
import 'package:get/get.dart';
import 'package:humming_bird/apis/message_api.dart';
import 'package:humming_bird/components/Models/message_model.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/services/encrypt_decrypt_service.dart';

/// WhatsApp-style group event messages ("You created this group", "Benu was
/// added by you", "You changed the group name to …", …).
///
/// These are REAL persisted message rows: `m_message_type = '7'` with the
/// event payload stored as structured JSON inside `m_message` (encrypted on
/// the wire exactly like every other message, decrypted before reading). They
/// flow through the existing `message/send-message` API + socket delivery, so
/// members see them in history, in the chat list preview and in realtime with
/// zero extra architecture.
///
/// The display string is ALWAYS derived from the JSON payload — never from the
/// raw text — so message content can never be spoofed as a system event.
class GroupSystemMessageService {
  GroupSystemMessageService._();

  /// Reserved message type used for persisted group events.
  static const String systemType = '7';

  /// True when [msg] is a persisted group event row.
  static bool isSystem(Messages msg) =>
      (msg.mMessageType ?? '').trim() == systemType;

  /// Parses the event payload. Local mirrors store the plaintext JSON;
  /// server-fetched copies are encrypted, so decrypt on demand.
  static Map<String, dynamic>? decodePayload(Messages msg) {
    final raw = (msg.mMessage ?? '').trim();
    if (raw.isEmpty) return null;
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      try {
        decoded = jsonDecode(EncryptionHelper().decryptMessage(raw));
      } catch (_) {
        decoded = null;
      }
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  /// Stable display text for the centered pill + chat list preview.
  ///
  /// Pure (no Get lookups) when [members] and [myUserId] are supplied, which
  /// keeps the formatter fully unit-testable.
  static String format(
    Messages msg, {
    List<User>? members,
    String? myUserId,
  }) {
    final payload = decodePayload(msg);
    if (payload == null) return '';
    final event = payload['event']?.toString() ?? '';
    final actorId = payload['actorId']?.toString();
    final targetIds = _stringList(payload['targetIds']);
    final newName = payload['newName']?.toString() ?? '';
    final actor = resolveName(actorId, members: members, myUserId: myUserId);

    String targets() {
      if (targetIds.isEmpty) return 'a member';
      final names = targetIds
          .map((id) => resolveName(id, members: members, myUserId: myUserId))
          .toList();
      if (names.length == 1) return names.first;
      if (names.length == 2) return '${names[0]} and ${names[1]}';
      return '${names.length} members';
    }

    switch (event) {
      case 'group_created':
        return '$actor created this group';
      case 'group_name_changed':
        return newName.isNotEmpty
            ? "$actor changed the group name to \"$newName\""
            : "$actor updated this group's name";
      case 'group_icon_changed':
        return "$actor changed this group's icon";
      case 'member_added':
        return '$actor added ${targets()}';
      case 'member_removed':
        return '$actor removed ${targets()}';
      case 'member_left':
        return '$actor left this group';
      case 'member_promoted':
        return '$actor made ${targets()} an admin';
      case 'member_demoted':
        return '$actor stopped ${targets()} from being an admin';
      default:
        return '';
    }
  }

  /// Chat-list preview (no leading "sender:" label — these are centered
  /// system rows, not member messages).
  static String preview(Messages msg) {
    return format(msg, myUserId: _currentUserId());
  }

  /// Resolves a user id to a display name.
  ///
  /// Priority: member list (fresh, from group info) → contact/phone cache →
  /// safe fallback. Returns "You" for the signed-in user.
  static String resolveName(
    String? userId, {
    List<User>? members,
    String? myUserId,
  }) {
    if (userId == null || userId.isEmpty) return 'Member';
    if (myUserId != null && myUserId.isNotEmpty && userId == myUserId) {
      return 'You';
    }
    for (final member in members ?? const <User>[]) {
      if (member.userId != userId) continue;
      final full =
          '${member.userFirstName ?? ''} ${member.userLastName ?? ''}'.trim();
      if (full.isNotEmpty) return full;
      if ((member.userMobileNum ?? '').isNotEmpty) return member.userMobileNum!;
    }
    try {
      if (Get.isRegistered<ContactController>()) {
        final local =
            Get.find<ContactController>().resolveUserNameLocal(userId);
        if (local.isNotEmpty) return local;
      }
    } catch (_) {}
    return 'Member';
  }

  /// Posts a persisted group event and mirrors it locally.
  ///
  /// Fire-and-forget by design: group operations are never blocked on the
  /// side-effect. Delivery to other members happens through the normal
  /// message pipeline (API → row → socket relay), so every device ends up
  /// with the same row in the same order.
  static Future<void> postEvent({
    required String roomId,
    required String event,
    String? actorId,
    List<String> targetIds = const [],
    String? prevName,
    String? newName,
  }) async {
    try {
      final roomIdT = roomId.toString();
      if (roomIdT.isEmpty) return;

      final chatController = Get.find<ChatController>();
      final userController = Get.find<UserController>();
      final actor =
          actorId?.toString() ?? userController.user?.userId?.toString() ?? '';
      final targetList = targetIds
          .map((t) => t.toString())
          .where((t) => t.isNotEmpty)
          .toList();

      // In-flight throttle: a double tap on a UI action must not post twice.
      final key =
          '$roomIdT|$event|$actor|${targetList.join(',')}|$prevName|$newName';
      final now = DateTime.now();
      final lastSeen = _recentPosts[key];
      if (lastSeen != null && now.difference(lastSeen).inSeconds < 3) return;
      _recentPosts[key] = now;
      if (_recentPosts.length > 48) {
        final expired = _recentPosts.entries
            .where((e) => now.difference(e.value).inSeconds > 60)
            .map((e) => e.key)
            .toList();
        for (final k in expired) {
          _recentPosts.remove(k);
        }
      }

      final payload = jsonEncode({
        'v': 1,
        'event': event,
        'actorId': actor,
        'targetIds': targetList,
        'prevName': (_isBlank(prevName)) ? null : prevName,
        'newName': (_isBlank(newName)) ? null : newName,
      });

      final messageData = <String, dynamic>{
        'm_room_id': roomIdT,
        'm_message_type': systemType,
        'm_message': EncryptionHelper().encryptMessage(payload),
        'm_sender_id': actor,
        'm_replied_on': '',
        'me': true,
        'receiver_id': '',
        'm_read_status': '0',
      };

      MessageModel? res;
      try {
        res = await MessageApi().sendMessage(messageData);
      } catch (_) {
        try {
          res = await MessageApi().sendMessage(messageData);
        } catch (_) {}
      }
      if (res == null || !(res.status ?? false) || res.msg == null) return;

      // Realtime relay to other members (persisted row already created).
      try {
        chatController.socket.emit('message', res.msg!.toJson());
      } catch (_) {}

      // Local mirror: plaintext JSON (same as outgoing text messages, which
      // are stored decrypted on the sending device).
      final confirmed = res.msg!..mMessage = payload;
      LocalDatabase.saveMessage([confirmed]);

      final previewMsg = Messages.fromJson(res.msg!.toJson())
        ..mMessage = payload;
      chatController.updateLocalRoomLastMessage(previewMsg);

      if (chatController.selectedRoom.value == roomIdT) {
        final idx =
            chatController.messages.indexWhere((e) => e.mId == confirmed.mId);
        if (idx >= 0) {
          chatController.messages[idx] = confirmed;
        } else {
          chatController.messages.insert(0, confirmed);
          chatController.messages
              .sort((a, b) => b.sentEpochSeconds.compareTo(a.sentEpochSeconds));
        }
        chatController.update();
      }
    } catch (_) {}
  }

  static String? _currentUserId() {
    try {
      if (Get.isRegistered<UserController>()) {
        return Get.find<UserController>().user?.userId;
      }
    } catch (_) {}
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  static final Map<String, DateTime> _recentPosts = {};
}
