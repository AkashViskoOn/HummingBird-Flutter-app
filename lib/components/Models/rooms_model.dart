import 'package:hive/hive.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
part 'rooms_model.g.dart';

class RoomsModel {
  bool? status;
  String? message;
  List<Rooms>? rooms;
  Rooms? room;

  RoomsModel({this.status, this.message, this.rooms, this.room});

  RoomsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['rooms'] != null) {
      rooms = <Rooms>[];
      json['rooms'].forEach((v) {
        rooms!.add(Rooms.fromJson(v));
      });
    }
    room = json['room'] != null ? Rooms.fromJson(json['room']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (rooms != null) {
      data['rooms'] = rooms!.map((v) => v.toJson()).toList();
    }
    if (room != null) {
      data['room'] = room!.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 1)
class Rooms extends HiveObject {
  @HiveField(0)
  String? rId;
  @HiveField(1)
  String? rUniqueId;
  @HiveField(2)
  String? rName;
  @HiveField(3)
  String? rType;
  @HiveField(4)
  String? rAvatar;
  @HiveField(5)
  String? rCreatedBy;
  @HiveField(6)
  String? rUsers;
  @HiveField(7)
  String? rAdmins;
  @HiveField(8)
  String? rStatus;
  @HiveField(9)
  Messages? rLastMessage;
  @HiveField(10)
  String? rUpdatedAt;
  @HiveField(11)
  String? rCreatedAt;
  @HiveField(12)
  String? userNumbers;
  @HiveField(13)
  String? rAdminNumber;
  @HiveField(14)
  String? rIsPending;
  @HiveField(15)
  String? rPendingPhone;

  // Server-computed unread message count for this user (from fetchRooms).
  // Intentionally NOT a Hive field — re-fetched on every room sync, so it
  // doesn't need to survive restarts (the HomeController unread map does).
  int unreadCount = 0;

  Rooms({
    this.rId,
    this.rUniqueId,
    this.rName,
    this.rType,
    this.rAvatar,
    this.rCreatedBy,
    this.rUsers,
    this.rAdmins,
    this.rStatus,
    this.rLastMessage,
    this.rUpdatedAt,
    this.rCreatedAt,
    this.userNumbers,
    this.rAdminNumber,
    this.rIsPending,
    this.rPendingPhone,
  });

  Rooms.fromJson(Map<String, dynamic> json) {
    rId = json['r_id'];
    rUniqueId = json['r_unique_id'];
    rName = json['r_name'];
    rType = json['r_type'];
    rAvatar = json['r_avatar'];
    rCreatedBy = json['r_created_by'];
    rUsers = json['r_users'];
    rAdmins = json['r_admins'];
    rStatus = json['r_status'];
    rStatus = json['r_status'];
    if (json['r_last_message'] != null && json['r_last_message'] != '') {
      rLastMessage = Messages.fromJson(json['r_last_message']);
    }
    rUpdatedAt = json['r_updated_at'];
    rCreatedAt = json['r_created_at'];
    userNumbers = json['user_numbers'];
    rAdminNumber = json['r_admin_number'];
    rIsPending = json['r_is_pending']?.toString();
    rPendingPhone = json['r_pending_phone']?.toString();
    unreadCount = int.tryParse(json['unread_count']?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['r_id'] = rId;
    data['r_unique_id'] = rUniqueId;
    data['r_name'] = rName;
    data['r_type'] = rType;
    data['r_avatar'] = rAvatar;
    data['r_created_by'] = rCreatedBy;
    data['r_users'] = rUsers;
    data['r_admins'] = rAdmins;
    data['r_status'] = rStatus;
    if (rLastMessage != null) {
      data['r_last_message'] = rLastMessage!.toJson();
    }
    data['r_updated_at'] = rUpdatedAt;
    data['r_created_at'] = rCreatedAt;
    data['user_numbers'] = userNumbers;
    data['r_is_pending'] = rIsPending;
    data['r_pending_phone'] = rPendingPhone;
    data['unread_count'] = unreadCount;
    return data;
  }
}
