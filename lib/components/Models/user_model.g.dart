// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      userId: fields[0] as String?,
      userFirstName: fields[1] as String?,
      userLastName: fields[2] as String?,
      userImage: fields[3] as String?,
      userDob: fields[4] as String?,
      userMobileNum: fields[5] as String?,
      userEmail: fields[6] as String?,
      userOtp: fields[7] as String?,
      userBio: fields[8] as String?,
      userProfileComplete: fields[9] as String?,
      userCreatedAt: fields[10] as String?,
      userUpdatedAt: fields[11] as String?,
      userBlockList: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.userFirstName)
      ..writeByte(2)
      ..write(obj.userLastName)
      ..writeByte(3)
      ..write(obj.userImage)
      ..writeByte(4)
      ..write(obj.userDob)
      ..writeByte(5)
      ..write(obj.userMobileNum)
      ..writeByte(6)
      ..write(obj.userEmail)
      ..writeByte(7)
      ..write(obj.userOtp)
      ..writeByte(8)
      ..write(obj.userBio)
      ..writeByte(9)
      ..write(obj.userProfileComplete)
      ..writeByte(10)
      ..write(obj.userCreatedAt)
      ..writeByte(11)
      ..write(obj.userUpdatedAt)
      ..writeByte(12)
      ..write(obj.userBlockList);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
