import 'package:humming_bird/components/Models/all_contacts_model.dart';

class ContactModel {
  bool? status;
  String? message;
  Contacts? contact;

  ContactModel({this.status, this.message, this.contact});

  ContactModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    contact =
        json['contact'] != null ? Contacts.fromJson(json['contact']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (contact != null) {
      data['contact'] = contact!.toJson();
    }
    return data;
  }
}

// class Contact {
//   String? cId;
//   String? cFirstName;
//   String? cLastName;
//   String? cMobileNumber;
//   String? cUniqueId;
//   String? cEmailAddress;
//   String? cNotes;
//   String? cUserId;
//   String? cDeletedAt;
//   String? cUpdatedAt;
//   String? cCreatedAt;
//
//   Contact(
//       {this.cId,
//       this.cFirstName,
//       this.cLastName,
//       this.cMobileNumber,
//       this.cUniqueId,
//       this.cEmailAddress,
//       this.cNotes,
//       this.cUserId,
//       this.cDeletedAt,
//       this.cUpdatedAt,
//       this.cCreatedAt});
//
//   Contact.fromJson(Map<String, dynamic> json) {
//     cId = json['c_id'];
//     cFirstName = json['c_first_name'];
//     cLastName = json['c_last_name'];
//     cMobileNumber = json['c_mobile_number'];
//     cUniqueId = json['c_unique_id'];
//     cEmailAddress = json['c_email_address'];
//     cNotes = json['c_notes'];
//     cUserId = json['c_user_id'];
//     cDeletedAt = json['c_deleted_at'];
//     cUpdatedAt = json['c_updated_at'];
//     cCreatedAt = json['c_created_at'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> database = new Map<String, dynamic>();
//     database['c_id'] = this.cId;
//     database['c_first_name'] = this.cFirstName;
//     database['c_last_name'] = this.cLastName;
//     database['c_mobile_number'] = this.cMobileNumber;
//     database['c_unique_id'] = this.cUniqueId;
//     database['c_email_address'] = this.cEmailAddress;
//     database['c_notes'] = this.cNotes;
//     database['c_user_id'] = this.cUserId;
//     database['c_deleted_at'] = this.cDeletedAt;
//     database['c_updated_at'] = this.cUpdatedAt;
//     database['c_created_at'] = this.cCreatedAt;
//     return database;
//   }
// }
