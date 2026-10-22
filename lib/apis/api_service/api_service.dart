import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/dio.dart' as dio_client;
import 'package:get/get.dart';
import 'package:humming_bird/apis/api_handlers/api_error_haldler.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/onboarding/onboarding_screen.dart';

/// Reusable class for APIs.
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late BirdController birdController;
  late UserController userController;
  late Dio dio;

  ApiService._internal() {
    birdController = Get.find();
    userController = Get.find();
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 45),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = userController.storage.read("userToken");
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          ApiHandler().logError(error);

          if (_shouldRetry(error)) {
            for (int i = 0; i < 2; i++) {
              await Future.delayed(const Duration(seconds: 1));
              try {
                final response = await dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (_) {
                continue;
              }
            }
          }

          if (error.type == DioExceptionType.badResponse) {
            final statusCode = error.response?.statusCode ?? 0;
            if (statusCode == 401) {
              // Full account wipe — otherwise the previous number's chats,
              // contacts and schedules stay in Hive + in-memory controllers
              // and show up after the next login.
              userController.purgeAccountData();
              Get.offAll(() => const OnboardingScreen());
              return handler.reject(error);
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  Options _authOptions(Options? options) {
    if (options != null) return options;
    final token = userController.storage.read("userToken");
    return Options(headers: {"Authorization": "Bearer $token"});
  }

  Map<String, dynamic> _errorResponse(DioException exception) {
    final data = exception.response?.data;
    if (data is Map<String, dynamic>) return data;
    return {};
  }

  Future<Map<String, dynamic>> getData({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final dio_client.Response res = await dio.get(
        path,
        queryParameters: queryParameters,
        options: _authOptions(options),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data;
      }
    } on DioException catch (e) {
      return _errorResponse(e);
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> getData1({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return getData(
      path: path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Map<String, dynamic>> post({
    required String path,
    required dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final dio_client.Response res = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _authOptions(options),
        onSendProgress: (uploaded, total) {
          if (total > 0) {
            birdController.uploadValue.value = uploaded / total;
          }
        },
      );

      print('[post] AI generate response: ${res.statusCode} ${res.data}');

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data;
      }
    } on DioException catch (e) {
      return _errorResponse(e);
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> deleteData({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final dio_client.Response res = await dio.delete(
        path,
        queryParameters: queryParameters,
        options: _authOptions(options),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data;
      }
    } on DioException catch (e) {
      return _errorResponse(e);
    } catch (_) {}
    return {};
  }

  Future<Uint8List?> downloadMedia({
    required String url,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? mediaId,
  }) async {
    try {
      final dio_client.Response res = await dio.get(
        url,
        queryParameters: queryParameters,
        options: options ??
            Options(
              responseType: ResponseType.bytes,
              headers: {
                "Authorization":
                    "Bearer ${userController.storage.read("userToken")}",
              },
            ),
        onReceiveProgress: (count, total) {
          if (total > 0) {
            birdController.downloadingMediaMap['${mediaId}_progress'] =
                count / total;
          }
        },
      );

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Uint8List) return data;
        if (data is List<int>) return Uint8List.fromList(data);
      }
    } catch (_) {}
    return null;
  }
}

bool _shouldRetry(DioException error) {
  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError;
}
