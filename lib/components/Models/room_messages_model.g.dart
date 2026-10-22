// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_messages_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessagesAdapter extends TypeAdapter<Messages> {
  @override
  final int typeId = 2;

  @override
  Messages read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Messages(
      mId: fields[0] as String?,
      mUniqueId: fields[1] as String?,
      mSenderId: fields[2] as String?,
      mReceiverId: fields[3] as String?,
      mRoomId: fields[4] as String?,
      mMessage: fields[5] as String?,
      mMessageType: fields[6] as String?,
      mMedia: fields[7] as String?,
      mIsScheduled: fields[8] as String?,
      mScheduledAt: fields[9] as String?,
      mScheduleId: fields[10] as String?,
      mIsDeleted: fields[11] as String?,
      mDeletedAt: fields[12] as String?,
      mIsLink: fields[13] as String?,
      mReadStatus: fields[14] as String?,
      mUpdatedAt: fields[15] as String?,
      mCreatedAt: fields[16] as String?,
      mReceiver: fields[17] as String?,
      me: fields[18] as bool?,
      interval: fields[19] as String?,
      count: fields[20] as String?,
      mRepliedOn: fields[21] as String?,
      showTyping: fields[22] as bool?,
      mSeenBy: fields[24] as String?,
      mTimeStamp: fields[23] as String?,
      mReactions: fields[25] as String?,
      mPinned: fields[26] as String?,
      mStarred: fields[27] as String?,
      mIsEdited: fields[28] as String?,
      mForwarded: fields[29] as String?,
      mForwardedFrom: fields[30] as String?,
      mPinnedAt: fields[31] as String?,
      mStatus: fields[32] as String?,
      mEpochTime: fields[33] as String?,
      mMentions: (fields[34] as List?)?.cast<String>(),
      mStoryRef: fields[35] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Messages obj) {
    writer
      ..writeByte(36)
      ..writeByte(0)
      ..write(obj.mId)
      ..writeByte(1)
      ..write(obj.mUniqueId)
      ..writeByte(2)
      ..write(obj.mSenderId)
      ..writeByte(3)
      ..write(obj.mReceiverId)
      ..writeByte(4)
      ..write(obj.mRoomId)
      ..writeByte(5)
      ..write(obj.mMessage)
      ..writeByte(6)
      ..write(obj.mMessageType)
      ..writeByte(7)
      ..write(obj.mMedia)
      ..writeByte(8)
      ..write(obj.mIsScheduled)
      ..writeByte(9)
      ..write(obj.mScheduledAt)
      ..writeByte(10)
      ..write(obj.mScheduleId)
      ..writeByte(11)
      ..write(obj.mIsDeleted)
      ..writeByte(12)
      ..write(obj.mDeletedAt)
      ..writeByte(13)
      ..write(obj.mIsLink)
      ..writeByte(14)
      ..write(obj.mReadStatus)
      ..writeByte(15)
      ..write(obj.mUpdatedAt)
      ..writeByte(16)
      ..write(obj.mCreatedAt)
      ..writeByte(33)
      ..write(obj.mEpochTime)
      ..writeByte(17)
      ..write(obj.mReceiver)
      ..writeByte(18)
      ..write(obj.me)
      ..writeByte(19)
      ..write(obj.interval)
      ..writeByte(20)
      ..write(obj.count)
      ..writeByte(21)
      ..write(obj.mRepliedOn)
      ..writeByte(22)
      ..write(obj.showTyping)
      ..writeByte(24)
      ..write(obj.mSeenBy)
      ..writeByte(23)
      ..write(obj.mTimeStamp)
      ..writeByte(25)
      ..write(obj.mReactions)
      ..writeByte(26)
      ..write(obj.mPinned)
      ..writeByte(27)
      ..write(obj.mStarred)
      ..writeByte(28)
      ..write(obj.mIsEdited)
      ..writeByte(29)
      ..write(obj.mForwarded)
      ..writeByte(30)
      ..write(obj.mForwardedFrom)
      ..writeByte(31)
      ..write(obj.mPinnedAt)
      ..writeByte(32)
      ..write(obj.mStatus)
      ..writeByte(34)
      ..write(obj.mMentions)
      ..writeByte(35)
      ..write(obj.mStoryRef);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
