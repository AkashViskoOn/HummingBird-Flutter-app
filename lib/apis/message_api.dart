import 'dart:convert';
import 'package:dio/dio.dart' as dio_client;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/Models/message_model.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';

class MessageApi {
  UserController userController = Get.find();
  ChatController chatController = Get.find();

  Future<RoomMessagesModel?> fetchAllMessages(roomId) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.fetchMessages, queryParameters: {'room_id': roomId});
      return RoomMessagesModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<MessageModel?> sendMessage(Map<String, dynamic> message) async {
    try {
      if (kDebugMode) {
        debugPrint('STATUS-REPLY-TRACE → MessageApi payload '
            'storyRef=${message['m_story_ref']}');
      }
      dio_client.FormData data = dio_client.FormData.fromMap({
        "room_id": message['m_room_id'],
        "message_type": message['m_message_type'],
        "message": message['m_message'],
        "is_scheduled": message['m_is_scheduled'],
        "scheduled_at": message['m_scheduled_at'],
        "receiver_id": message['receiver_id'],
        'm_interval': message['m_interval'],
        'm_count': message['m_count'],
        'm_replied_on': message['m_replied_on'],
        'm_story_ref': message['m_story_ref'],
      });

      Map<String, dynamic> res =
          await ApiService().post(path: Endpoints.sendMessage, data: data);
      return MessageModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> deleteMessage(
      List<String> messageId, String deleteFor) async {
    try {
      Map<String, dynamic> res = await ApiService().getData(
          path: Endpoints.deleteMessage,
          queryParameters: {
            'message_id': jsonEncode(messageId),
            'delete_for': deleteFor
          });
      return res;
    } catch (_) {
      return {};
    }
  }

  Future<MessageModel?> sendFormData(
      {required dio_client.FormData formData,
      Map<String, dynamic>? queryParameters}) async {
    try {
      chatController.uploadingFile.value = true;
      Map<String, dynamic> res = await ApiService().post(
        path: Endpoints.sendMessage,
        data: formData,
      );
      return MessageModel.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  Future<MessageModel?> updateMessage(Map<String, dynamic> message) async {
    try {
      dio_client.FormData messageData = dio_client.FormData.fromMap({
        'm_id': message['m_id'],
        'new_message': message['new_message'],
        'message_status': message['message_status'],
        'seen_by': message['seen_by'],
        'scheduled_at': message['scheduled_at'],
        'm_interval': message['m_interval'],
        'm_count': message['m_count'],
      });

      Map<String, dynamic> data = await ApiService()
          .post(path: Endpoints.updateMessage, data: messageData);
      return MessageModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Messages>> getAllScheduledMessages() async {
    try {
      Map<String, dynamic> data =
          await ApiService().getData(path: Endpoints.fetchScheduledMessages);
      List<Messages> scheduledMessages = [];
      if (data['data'] is List) {
        scheduledMessages =
            (data['data'] as List).map((e) => Messages.fromJson(e)).toList();
      }
      return scheduledMessages;
    } catch (_) {
      return [];
    }
  }

  Future<List<Messages>> searchSchedules(String keyword) async {
    try {
      Map<String, dynamic> data = await ApiService().getData(
        path: Endpoints.searchScheduledMessages,
        queryParameters: {'keyword': keyword},
      );
      List<Messages> results = [];
      if (data['data'] is List) {
        results =
            (data['data'] as List).map((e) => Messages.fromJson(e)).toList();
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> cancelScheduledMessage(String messageId) async {
    try {
      var res = await ApiService().getData(
          path: Endpoints.deleteScheduledMessages,
          queryParameters: {'message_id': messageId});
      return res;
    } catch (_) {
      return {};
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // PHASE 1 - ADVANCED CHAT FEATURES
  // ══════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> toggleReaction(
      String messageId, String emoji) async {
    try {
      return await ApiService().post(
          path: Endpoints.toggleReaction,
          data: {'m_id': messageId, 'emoji': emoji});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> pinMessage(String messageId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.pinMessage, queryParameters: {'m_id': messageId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> unpinMessage(String messageId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.unpinMessage, queryParameters: {'m_id': messageId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> starMessage(String messageId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.starMessage, queryParameters: {'m_id': messageId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> unstarMessage(String messageId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.unstarMessage, queryParameters: {'m_id': messageId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> forwardMessage(
      {required List<String> messageIds, required List<String> roomIds}) async {
    try {
      final dio_client.FormData data = dio_client.FormData.fromMap({
        'message_ids': jsonEncode(messageIds),
        'room_ids': jsonEncode(roomIds),
      });
      return await ApiService()
          .post(path: Endpoints.forwardMessage, data: data);
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> forwardMedia(
      {required String messageId, required String roomId}) async {
    return await forwardMessage(
      messageIds: [messageId],
      roomIds: [roomId],
    );
  }

  Future<Map<String, dynamic>> fetchMessageInfo(String messageId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.messageInfo, queryParameters: {'m_id': messageId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchPinnedMessages(String roomId) async {
    try {
      return await ApiService().getData(
          path: Endpoints.fetchPinnedMessages,
          queryParameters: {'room_id': roomId});
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchStarredMessages() async {
    try {
      return await ApiService().getData(path: Endpoints.fetchStarredMessages);
    } catch (_) {
      return {};
    }
  }
}
