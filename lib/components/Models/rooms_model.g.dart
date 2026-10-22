// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rooms_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoomsAdapter extends TypeAdapter<Rooms> {
  @override
  final int typeId = 1;

  @override
  Rooms read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Rooms(
      rId: fields[0] as String?,
      rUniqueId: fields[1] as String?,
      rName: fields[2] as String?,
      rType: fields[3] as String?,
      rAvatar: fields[4] as String?,
      rCreatedBy: fields[5] as String?,
      rUsers: fields[6] as String?,
      rAdmins: fields[7] as String?,
      rStatus: fields[8] as String?,
      rLastMessage: fields[9] as Messages?,
      rUpdatedAt: fields[10] as String?,
      rCreatedAt: fields[11] as String?,
      userNumbers: fields[12] as String?,
      rAdminNumber: fields[13] as String?,
      rIsPending: fields[14] as String?,
      rPendingPhone: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Rooms obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.rId)
      ..writeByte(1)
      ..write(obj.rUniqueId)
      ..writeByte(2)
      ..write(obj.rName)
      ..writeByte(3)
      ..write(obj.rType)
      ..writeByte(4)
      ..write(obj.rAvatar)
      ..writeByte(5)
      ..write(obj.rCreatedBy)
      ..writeByte(6)
      ..write(obj.rUsers)
      ..writeByte(7)
      ..write(obj.rAdmins)
      ..writeByte(8)
      ..write(obj.rStatus)
      ..writeByte(9)
      ..write(obj.rLastMessage)
      ..writeByte(10)
      ..write(obj.rUpdatedAt)
      ..writeByte(11)
      ..write(obj.rCreatedAt)
      ..writeByte(12)
      ..write(obj.userNumbers)
      ..writeByte(13)
      ..write(obj.rAdminNumber)
      ..writeByte(14)
      ..write(obj.rIsPending)
      ..writeByte(15)
      ..write(obj.rPendingPhone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
