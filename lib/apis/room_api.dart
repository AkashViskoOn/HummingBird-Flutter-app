import 'dart:convert';
import 'package:get/get.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/Models/group_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:dio/dio.dart' as dioClient;

class RoomApi {
  UserController userController = Get.find();

  Future<RoomsModel?> createRoom(roomType, roomName, participants) async {
    try {
      var participantsData = jsonEncode(participants);
      dioClient.FormData data = dioClient.FormData.fromMap({
        'r_type': roomType,
        'r_name': roomName,
        'contact_id': 0,
        'participants': participantsData
      });
      Map<String, dynamic> res =
          await ApiService().post(path: Endpoints.createRooms, data: data);
      return RoomsModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<RoomsModel?> fetchAllRooms(roomType) async {
    try {
      Map<String, dynamic> res = await ApiService().getData1(
          path: Endpoints.fetchRooms, queryParameters: {'room_type': roomType});
      return RoomsModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<RoomsModel> updateRoom(dioClient.FormData data) async {
    try {
      Map<String, dynamic> groupData =
          await ApiService().post(path: Endpoints.updateGroup, data: data);
      return RoomsModel.fromJson(groupData);
    } catch (_) {
      return RoomsModel.fromJson({});
    }
  }

  Future<GroupModel> addGroupMembers(roomId, participants) async {
    try {
      var participantsData = jsonEncode(participants);
      dioClient.FormData data = dioClient.FormData.fromMap(
          {'room_id': roomId, 'participants': participantsData});
      Map<String, dynamic> res =
          await ApiService().post(path: Endpoints.addGroupMembers, data: data);
      return GroupModel.fromJson(res);
    } catch (_) {
      return GroupModel.fromJson({});
    }
  }

  Future<RoomsModel?> makeUserAdmin(roomId, userId) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.makeAdmin,
          queryParameters: {'room_id': roomId, 'user_id': userId});
      return RoomsModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<RoomsModel?> removeAdmin(roomId, userId) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.removeFromAdmin,
          queryParameters: {'room_id': roomId, 'user_id': userId});
      return RoomsModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<GroupModel> leaveGroup(roomId, userId) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.leaveGroup,
          queryParameters: {'room_id': roomId, 'user_id': userId});
      return GroupModel.fromJson(res);
    } catch (_) {
      return GroupModel.fromJson({});
    }
  }

  Future<GroupModel> fetchGroup(roomId) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.fetchGroupInfo, queryParameters: {'room_id': roomId});
      return GroupModel.fromJson(res);
    } catch (_) {
      return GroupModel.fromJson({});
    }
  }

  Future<Map<String, dynamic>> deleteRoom(String roomId) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.deleteRoom, queryParameters: {'room_id': roomId});
      return res;
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> toggleArchive(String roomId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.toggleArchive, queryParameters: {'room_id': roomId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> toggleFavorite(String roomId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.toggleFavorite, queryParameters: {'room_id': roomId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> toggleMute(String roomId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.toggleMute, queryParameters: {'room_id': roomId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> markRead(String roomId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.markRead, queryParameters: {'room_id': roomId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> markUnread(String roomId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.markUnread, queryParameters: {'room_id': roomId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> checkUserByNumber(String phone) async {
    try {
      return await ApiService().getData(
          path: Endpoints.checkUserByNumber, queryParameters: {'phone': phone});
    } catch (_) {
      return {};
    }
  }

  Future<RoomsModel?> createPendingRoom(String phoneNumber) async {
    try {
      final data = dioClient.FormData.fromMap({'phone_number': phoneNumber});
      final res = await ApiService()
          .post(path: Endpoints.createPendingRoom, data: data);
      if (res['status'] == true && res['room'] != null) {
        return RoomsModel.fromJson(res);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> attachPendingRooms(String phone) async {
    try {
      final res = await ApiService().getData(
          path: Endpoints.attachPendingRooms,
          queryParameters: {'phone': phone});
      if (res['status'] == true && res['rooms'] is List) {
        return res['rooms'] as List;
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
