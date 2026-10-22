import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ApiHandler {
  static const List<String> _routeNotFoundMessages = [
    'route not found',
    '404',
    'not found',
    'missing endpoint',
    'wrong url',
    'invalid url',
  ];

  String getExceptionMessage(DioException exception) {
    if (exception.type == DioExceptionType.badResponse) {
      final statusCode = exception.response?.statusCode ?? 0;
      final data = exception.response?.data;

      if (statusCode == 401) {
        return '';
      }

      if (statusCode == 403) {
        return '';
      }

      if (statusCode == 404 || statusCode == 500) {
        return '';
      }

      if (data is Map<String, dynamic> && data['message'] != null) {
        final msg = data['message'].toString().toLowerCase();
        for (final pattern in _routeNotFoundMessages) {
          if (msg.contains(pattern)) {
            return '';
          }
        }
      }

      return '';
    }

    if (exception.type == DioExceptionType.connectionTimeout) {
      return 'Connection is slow. Please check your network.';
    }
    if (exception.type == DioExceptionType.receiveTimeout) {
      return 'Server is not responding. Please try again.';
    }
    if (exception.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }
    if (exception.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }

    return '';
  }

  void logError(DioException exception) {
    if (kDebugMode) {
      debugPrint('[API Error] ${exception.type}: ${exception.message}');
      _traceNetworkError(exception);
    }
  }

  /// Persists a raw API-failure line to the app's external files dir and
  /// logcat (prefixed API-TRACE), so failures during outage windows can be
  /// read from the device without a debugger. File:
  /// `Android/data/<pkg>/files/api_trace.txt`. Mirrors the call controller's
  /// `_trace()` pattern. Failures are swallowed on purpose — observability
  /// must never break the caller.
  void _traceNetworkError(DioException exception) {
    final ts = DateTime.now().toIso8601String();
    final statusCode = exception.response?.statusCode;
    final method = exception.requestOptions.method;
    final path = exception.requestOptions.path;
    debugPrint('API-TRACE $ts [$method] $path ${statusCode ?? ''}');
    try {
      getExternalStorageDirectory().then((dir) async {
        if (dir == null) return;
        final file = File('${dir.path}/api_trace.txt');
        try {
          await file.writeAsString(
            '$ts [$method] $path ${statusCode ?? ''} '
            'type=${exception.type.name}\n',
            mode: FileMode.append,
            flush: true,
          );
        } catch (_) {}
      });
    } catch (_) {}
  }
}
