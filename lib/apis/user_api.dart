import 'package:get/get.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';

class UserApi {
  BirdController birdController = Get.find();
  UserController userController = Get.find();

  Future<UserModel?> updateUser(userData) async {
    try {
      Map<String, dynamic> res =
          await ApiService().post(path: Endpoints.updateUser, data: userData);
      return UserModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUserData(userId) async {
    try {
      Map<String, dynamic> userData = await ApiService().getData(
          path: Endpoints.getUser, queryParameters: {'user_id': userId});
      return UserModel.fromJson(userData);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> requestAccountChanges(
      String phoneNumber, bool forDeleteAccount) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: forDeleteAccount
              ? Endpoints.requestAccountDelete
              : Endpoints.requestChangeNumber,
          queryParameters: {'user_number': phoneNumber});
      return res;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> changeNumber(
      String newNumber, String otp) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.changeNumber,
          queryParameters: {'new_number': newNumber, 'otp': otp});
      return res;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String otp) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.deleteAccount, queryParameters: {'otp': otp});
      return res;
    } catch (_) {
      return {};
    }
  }

  Future<UserModel> blockUser(String userId) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.blockUser, queryParameters: {'block_id': userId});
      return UserModel.fromJson(res);
    } catch (_) {
      return UserModel.fromJson({});
    }
  }

  Future<UserModel> unBlockUser(String userId) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.unBlockUser, queryParameters: {'blocked_id': userId});
      return UserModel.fromJson(res);
    } catch (_) {
      return UserModel.fromJson({});
    }
  }

  Future<Map<String, dynamic>> reportUser(String userId, String report) async {
    try {
      Map<String, dynamic> res = await ApiService().post(
          path: Endpoints.reportUser,
          data: {'reported_id': userId, 'report': report});
      return res;
    } catch (_) {
      return {};
    }
  }
}
