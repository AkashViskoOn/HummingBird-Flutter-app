import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';

class GroupModel {
  bool? status;
  String? message;
  Rooms? room;
  List<User>? members;

  GroupModel({this.status, this.message, this.room, this.members});

  GroupModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    room = json['room'] != null ? Rooms.fromJson(json['room']) : null;
    if (json['members'] != null) {
      members = <User>[];
      json['members'].forEach((v) {
        members!.add(User.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (room != null) {
      data['room'] = room!.toJson();
    }
    if (members != null) {
      data['members'] = members!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
