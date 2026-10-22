import 'package:humming_bird/components/Models/room_messages_model.dart';

class MessageModel {
  bool? status;
  String? message;
  Messages? msg;

  MessageModel({this.status, this.message, this.msg});

  MessageModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    msg = json['msg'] != null ? Messages.fromJson(json['msg']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (msg != null) {
      data['msg'] = msg!.toJson();
    }
    return data;
  }
}
