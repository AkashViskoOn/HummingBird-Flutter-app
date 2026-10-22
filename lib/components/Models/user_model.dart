import 'package:hive/hive.dart';
part 'user_model.g.dart';

class UserModel {
  bool? status;
  String? message;
  String? token;
  List<User>? data;
  User? user;

  UserModel({this.status, this.message, this.token, this.data, this.user});

  UserModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    token = json['token'];
    if (json['data'] != null) {
      data = <User>[];
      json['data'].forEach((v) {
        data!.add(User.fromJson(v));
      });
    }
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String? userId;
  @HiveField(1)
  String? userFirstName;
  @HiveField(2)
  String? userLastName;
  @HiveField(3)
  String? userImage;
  @HiveField(4)
  String? userDob;
  @HiveField(5)
  String? userMobileNum;
  @HiveField(6)
  String? userEmail;
  @HiveField(7)
  String? userOtp;
  @HiveField(8)
  String? userBio;
  @HiveField(9)
  String? userProfileComplete;
  @HiveField(10)
  String? userCreatedAt;
  @HiveField(11)
  String? userUpdatedAt;
  @HiveField(12)
  String? userBlockList;

  User({
    this.userId,
    this.userFirstName,
    this.userLastName,
    this.userImage,
    this.userDob,
    this.userMobileNum,
    this.userEmail,
    this.userOtp,
    this.userBio,
    this.userProfileComplete,
    this.userCreatedAt,
    this.userUpdatedAt,
    this.userBlockList,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  User.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    userFirstName = json['user_first_name'];
    userLastName = json['user_last_name'];
    userImage = json['user_image'];
    userDob = json['user_dob'];
    userMobileNum = json['user_mobile_num'];
    userEmail = json['user_email'];
    userOtp = json['user_otp'];
    userBio = json['user_bio'];
    userProfileComplete = json['user_profile_complete'];
    userCreatedAt = json['user_created_at'];
    userUpdatedAt = json['user_updated_at'];
    userBlockList = json['u_block_list'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = userId;
    data['user_first_name'] = userFirstName;
    data['user_last_name'] = userLastName;
    data['user_image'] = userImage;
    data['user_dob'] = userDob;
    data['user_mobile_num'] = userMobileNum;
    data['user_email'] = userEmail;
    data['user_otp'] = userOtp;
    data['user_bio'] = userBio;
    data['user_profile_complete'] = userProfileComplete;
    data['user_created_at'] = userCreatedAt;
    data['user_updated_at'] = userUpdatedAt;
    data['u_block_list'] = userBlockList;
    return data;
  }
}
