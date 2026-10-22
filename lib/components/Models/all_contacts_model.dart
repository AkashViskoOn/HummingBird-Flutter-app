import 'package:hive/hive.dart';

class AllContactsModel {
  bool? status;
  String? message;
  List<Contacts>? contacts;

  AllContactsModel({this.status, this.message, this.contacts});

  AllContactsModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['contacts'] != null) {
      contacts = <Contacts>[];
      json['contacts'].forEach((v) {
        contacts!.add(Contacts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (contacts != null) {
      data['contacts'] = contacts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Contacts extends HiveObject {
  String? cId;
  String? cFirstName;
  String? cLastName;
  String? cMobileNumber;
  String? cUniqueId;
  String? cEmailAddress;
  String? cNotes;
  String? cUserId;
  String? cDeletedAt;
  String? cUpdatedAt;
  String? cCreatedAt;

  Contacts(
      {this.cId,
      this.cFirstName,
      this.cLastName,
      this.cMobileNumber,
      this.cUniqueId,
      this.cEmailAddress,
      this.cNotes,
      this.cUserId,
      this.cDeletedAt,
      this.cUpdatedAt,
      this.cCreatedAt});

  Contacts.fromJson(Map<String, dynamic> json) {
    cId = json['c_id'];
    cFirstName = json['c_first_name'];
    cLastName = json['c_last_name'];
    cMobileNumber = json['c_mobile_number'];
    cUniqueId = json['c_unique_id'];
    cEmailAddress = json['c_email_address'];
    cNotes = json['c_notes'];
    cUserId = json['c_user_id'];
    cDeletedAt = json['c_deleted_at'];
    cUpdatedAt = json['c_updated_at'];
    cCreatedAt = json['c_created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['c_id'] = cId;
    data['c_first_name'] = cFirstName;
    data['c_last_name'] = cLastName;
    data['c_mobile_number'] = cMobileNumber;
    data['c_unique_id'] = cUniqueId;
    data['c_email_address'] = cEmailAddress;
    data['c_notes'] = cNotes;
    data['c_user_id'] = cUserId;
    data['c_deleted_at'] = cDeletedAt;
    data['c_updated_at'] = cUpdatedAt;
    data['c_created_at'] = cCreatedAt;
    return data;
  }
}
