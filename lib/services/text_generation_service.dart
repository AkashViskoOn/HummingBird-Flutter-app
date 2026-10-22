import 'package:flutter/foundation.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/res/endpoints.dart';

class TextGeneration {
  Future<String?> getGeneratedText(String prompt) async {
    try {
      final response = await ApiService().post(
        path: Endpoints.aiGenerateMessage,
        data: {'prompt': prompt},
      );

      print('[TextGeneration] AI generate response: $response');
      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];
        if (data is Map<String, dynamic> && data['text'] != null) {
          return data['text'].toString();
        }
        if (data is String) {
          return data;
        }
      }

      if (kDebugMode) {
        debugPrint(
            '[TextGeneration] AI generate failed — status: ${response['status']}, message: ${response['message']}');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TextGeneration] AI generate error: $e');
      }
      return null;
    }
  }
}
