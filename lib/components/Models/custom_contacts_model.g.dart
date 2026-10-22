// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_contacts_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomContactsModelAdapter extends TypeAdapter<CustomContactsModel> {
  @override
  final int typeId = 4;

  @override
  CustomContactsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomContactsModel(
      id: fields[0] as String?,
      displayName: fields[1] as String?,
      number: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomContactsModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.number);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomContactsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
