// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaModelAdapter extends TypeAdapter<MediaModel> {
  @override
  final int typeId = 3;

  @override
  MediaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaModel(
      id: fields[0] as String?,
      mediaRoomId: fields[1] as String?,
      mediaPath: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MediaModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mediaRoomId)
      ..writeByte(2)
      ..write(obj.mediaPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
