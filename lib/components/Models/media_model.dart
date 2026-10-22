import 'package:hive/hive.dart';
part 'media_model.g.dart';

@HiveType(typeId: 3)
class MediaModel extends HiveObject {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final String? mediaRoomId;
  @HiveField(2)
  final String? mediaPath;

  MediaModel({
    this.id,
    this.mediaRoomId,
    this.mediaPath,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      id: json['id'],
      mediaRoomId: json['mediaRoomId'],
      mediaPath: json['mediaPath'],
    );
  }

  // ToJson Method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaRoomId': mediaRoomId,
      'mediaPath': mediaPath,
    };
  }
}
