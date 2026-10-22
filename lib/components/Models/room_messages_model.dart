import 'dart:convert';

import 'package:hive/hive.dart';
part 'room_messages_model.g.dart';

class RoomMessagesModel {
  bool? status;
  String? message;
  RoomMessages? room;

  RoomMessagesModel({this.status, this.message, this.room});

  RoomMessagesModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    room = json['room'] != null ? RoomMessages.fromJson(json['room']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = status;
    data['message'] = message;
    if (room != null) {
      data['room'] = room!.toJson();
    }
    return data;
  }
}

class RoomMessages extends HiveObject {
  String? rId;
  String? rUniqueId;
  String? rName;
  String? rType;
  String? rAvatar;
  String? rCreatedBy;
  String? rUsers;
  String? rAdmins;
  String? rStatus;
  String? rUpdatedAt;
  String? rCreatedAt;
  List<Messages>? messages;

  RoomMessages({
    this.rId,
    this.rUniqueId,
    this.rName,
    this.rType,
    this.rAvatar,
    this.rCreatedBy,
    this.rUsers,
    this.rAdmins,
    this.rStatus,
    this.rUpdatedAt,
    this.rCreatedAt,
    this.messages,
  });

  RoomMessages.fromJson(Map<String, dynamic> json) {
    rId = json['r_id'];
    rUniqueId = json['r_unique_id'];
    rName = json['r_name'];
    rType = json['r_type'];
    rAvatar = json['r_avatar'];
    rCreatedBy = json['r_created_by'];
    rUsers = json['r_users'];
    rAdmins = json['r_admins'];
    rStatus = json['r_status'];
    rUpdatedAt = json['r_updated_at'];
    rCreatedAt = json['r_created_at'];
    if (json['messages'] != null) {
      messages = <Messages>[];
      json['messages'].forEach((v) {
        messages!.add(Messages.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['r_id'] = rId;
    data['r_unique_id'] = rUniqueId;
    data['r_name'] = rName;
    data['r_type'] = rType;
    data['r_avatar'] = rAvatar;
    data['r_created_by'] = rCreatedBy;
    data['r_users'] = rUsers;
    data['r_admins'] = rAdmins;
    data['r_status'] = rStatus;
    data['r_updated_at'] = rUpdatedAt;
    data['r_created_at'] = rCreatedAt;
    if (messages != null) {
      data['messages'] = messages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@HiveType(typeId: 2)
class Messages extends HiveObject {
  @HiveField(0)
  String? mId;
  @HiveField(1)
  String? mUniqueId;
  @HiveField(2)
  String? mSenderId;
  @HiveField(3)
  String? mReceiverId;
  @HiveField(4)
  String? mRoomId;
  @HiveField(5)
  String? mMessage;
  @HiveField(6)
  String? mMessageType;
  @HiveField(7)
  String? mMedia;
  @HiveField(8)
  String? mIsScheduled;
  @HiveField(9)
  String? mScheduledAt;
  @HiveField(10)
  String? mScheduleId;
  @HiveField(11)
  String? mIsDeleted;
  @HiveField(12)
  String? mDeletedAt;
  @HiveField(13)
  String? mIsLink;
  @HiveField(14)
  String? mReadStatus;
  @HiveField(15)
  String? mUpdatedAt;
  @HiveField(16)
  String? mCreatedAt;
  @HiveField(33)
  String? mEpochTime;
  @HiveField(17)
  String? mReceiver;
  @HiveField(18)
  bool? me;
  @HiveField(19)
  String? interval;
  @HiveField(20)
  String? count;
  @HiveField(21)
  String? mRepliedOn;
  @HiveField(22)
  bool? showTyping;
  @HiveField(24)
  String? mSeenBy;
  @HiveField(23)
  String? mTimeStamp;
  @HiveField(25)
  String? mReactions;
  @HiveField(26)
  String? mPinned;
  @HiveField(27)
  String? mStarred;
  @HiveField(28)
  String? mIsEdited;
  @HiveField(29)
  String? mForwarded;
  @HiveField(30)
  String? mForwardedFrom;
  @HiveField(31)
  String? mPinnedAt;
  @HiveField(32)
  String? mStatus;
  @HiveField(34)
  List<String>? mMentions;
  @HiveField(35)
  String? mStoryRef;

  Messages({
    this.mId,
    this.mUniqueId,
    this.mSenderId,
    this.mReceiverId,
    this.mRoomId,
    this.mMessage,
    this.mMessageType,
    this.mMedia,
    this.mIsScheduled,
    this.mScheduledAt,
    this.mScheduleId,
    this.mIsDeleted,
    this.mDeletedAt,
    this.mIsLink,
    this.mReadStatus,
    this.mUpdatedAt,
    this.mCreatedAt,
    this.mReceiver,
    this.me,
    this.interval,
    this.count,
    this.mRepliedOn,
    this.showTyping,
    this.mSeenBy,
    this.mTimeStamp,
    this.mReactions,
    this.mPinned,
    this.mStarred,
    this.mIsEdited,
    this.mForwarded,
    this.mForwardedFrom,
    this.mPinnedAt,
    this.mStatus,
    this.mEpochTime,
    this.mMentions,
    this.mStoryRef,
  });

  String? _asString(dynamic value) => value?.toString();

  /// True when the message is still pending delivery (scheduled) or was
  /// delivered from a schedule (kept its original `m_scheduled_at`).
  bool get isScheduledMessage =>
      mIsScheduled == '1' ||
      (mScheduledAt != null && mScheduledAt!.isNotEmpty && mScheduledAt != '0');

  /// Epoch seconds the message was actually sent (0 when unknown).
  int get sentEpochSeconds {
    final epoch = int.tryParse(mEpochTime ?? '');
    if (epoch != null && epoch > 0) return epoch;
    final createdAt = DateTime.tryParse(mCreatedAt ?? '');
    if (createdAt != null) return createdAt.millisecondsSinceEpoch ~/ 1000;
    final updatedAt = DateTime.tryParse(mUpdatedAt ?? '');
    if (updatedAt != null) return updatedAt.millisecondsSinceEpoch ~/ 1000;
    return 0;
  }

  Messages.fromJson(Map<String, dynamic> json) {
    mId = _asString(json['m_id']);
    mUniqueId = _asString(json['m_unique_id']);
    mSenderId = _asString(json['m_sender_id']);
    mReceiverId = _asString(json['m_receiver_id']);
    mRoomId = _asString(json['m_room_id']);
    mMessage = _asString(json['m_message']);
    mMessageType = _asString(json['m_message_type']);
    mMedia = _asString(json['m_media']);
    mIsScheduled = _asString(json['m_is_scheduled']);
    mScheduledAt = _asString(json['m_scheduled_at']);
    mScheduleId = _asString(json['m_schedule_id']);
    mIsDeleted = _asString(json['m_is_deleted']);
    mDeletedAt = _asString(json['m_deleted_at']);
    mIsLink = _asString(json['m_is_link']);
    mReadStatus = _asString(json['m_read_status']);
    mUpdatedAt = _asString(json['m_updated_at']);
    mCreatedAt = _asString(json['m_created_at']);
    mReceiver = _asString(json['m_receiver_name']);
    me = json['me'];
    interval = _asString(json['m_interval']);
    count = _asString(json['m_count']);
    mRepliedOn = _asString(json['m_replied_on']);
    mSeenBy = _asString(json['m_seen_by']);
    mTimeStamp = _asString(json['m_timestamp']);
    mReactions = _asString(json['m_reactions']);
    mPinned = _asString(json['m_pinned']);
    mStarred = _asString(json['m_starred']);
    mIsEdited = _asString(json['m_is_edited']);
    mForwarded = _asString(json['m_forwarded']);
    mForwardedFrom = _asString(json['m_forwarded_from']);
    mPinnedAt = _asString(json['m_pinned_at']);
    mStatus = _asString(json['m_status']);
    mEpochTime = _asString(json['m_epoch_time']);
    if (json['m_mentions'] is List) {
      mMentions = (json['m_mentions'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      final raw = _asString(json['m_mentions']);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            mMentions = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      }
    }
    mStoryRef = _asString(json['m_story_ref']);
  }

  /// Parsed story-reference payload (status reply/reaction/forward delivered
  /// as a chat message). Contains story_id, story_owner_id, reply_type,
  /// message, reaction, media_url, media_type, content, bg_color, text_color.
  Map<String, dynamic>? get storyRef {
    if (mStoryRef == null || mStoryRef!.isEmpty) return null;
    try {
      final decoded = jsonDecode(mStoryRef!);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['m_id'] = mId;
    data['m_unique_id'] = mUniqueId;
    data['m_sender_id'] = mSenderId;
    data['m_receiver_id'] = mReceiverId;
    data['m_room_id'] = mRoomId;
    data['m_message'] = mMessage;
    data['m_message_type'] = mMessageType;
    data['m_media'] = mMedia;
    data['m_is_scheduled'] = mIsScheduled;
    data['m_scheduled_at'] = mScheduledAt;
    data['m_schedule_id'] = mScheduleId;
    data['m_is_deleted'] = mIsDeleted;
    data['m_deleted_at'] = mDeletedAt;
    data['m_is_link'] = mIsLink;
    data['m_read_status'] = mReadStatus;
    data['m_updated_at'] = mUpdatedAt;
    data['m_created_at'] = mCreatedAt;
    data['m_receiver_name'] = mReceiver;
    data['me'] = me;
    data['m_interval'] = interval;
    data['m_count'] = count;
    data['m_replied_on'] = mRepliedOn;
    data['m_seen_by'] = mSeenBy;
    data['m_reactions'] = mReactions;
    data['m_pinned'] = mPinned;
    data['m_starred'] = mStarred;
    data['m_is_edited'] = mIsEdited;
    data['m_forwarded'] = mForwarded;
    data['m_forwarded_from'] = mForwardedFrom;
    data['m_pinned_at'] = mPinnedAt;
    data['m_status'] = mStatus;
    data['m_epoch_time'] = mEpochTime;
    data['m_mentions'] = mMentions;
    data['m_story_ref'] = mStoryRef;
    return data;
  }
}
