import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/res/endpoints.dart';

class ScheduledMomentApi {
  Future<Map<String, dynamic>?> schedule(Map<String, dynamic> body,
      {File? file}) async {
    try {
      if (file != null) {
        final formData = dio.FormData.fromMap({
          ...body,
          'media_file': await dio.MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });
        final res = await ApiService()
            .post(path: Endpoints.momentUpload, data: formData);
        if (res['status'] == true && res['data'] != null) return res['data'];
        return null;
      }
      final res =
          await ApiService().post(path: Endpoints.momentSchedule, data: body);
      if (res['status'] == true && res['data'] != null) return res['data'];
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<ScheduledMoment>> fetchList() async {
    try {
      final res = await ApiService().getData(path: Endpoints.momentList);
      if (res['status'] == true && res['data'] != null) {
        final dynamic data = res['data'];
        final dynamic moments = data is Map ? data['moments'] : data;
        if (moments is List) {
          return moments.map((e) => ScheduledMoment.fromJson(e)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<ScheduledMoment>> fetchDrafts() async {
    try {
      final res = await ApiService().getData(path: Endpoints.momentDrafts);
      if (res['status'] == true && res['data'] is List) {
        return (res['data'] as List)
            .map((e) => ScheduledMoment.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, List<ScheduledMoment>>?> fetchCalendar() async {
    try {
      final res = await ApiService().getData(path: Endpoints.momentCalendar);
      if (res['status'] == true && res['data'] != null) {
        final map = <String, List<ScheduledMoment>>{};
        final dynamic data = res['data'];
        if (data is Map) {
          data.forEach((key, value) {
            if (value is List) {
              map[key] = value.map((e) => ScheduledMoment.fromJson(e)).toList();
            }
          });
        } else if (data is List) {
          for (final entry in data) {
            if (entry is Map<String, dynamic> &&
                entry['date'] != null &&
                entry['moments'] is List) {
              map[entry['date'].toString()] = (entry['moments'] as List)
                  .map((e) => ScheduledMoment.fromJson(e))
                  .toList();
            }
          }
        }
        return map;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveDraft(Map<String, dynamic> body) async {
    try {
      final res =
          await ApiService().post(path: Endpoints.momentSaveDraft, data: body);
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final res =
          await ApiService().deleteData(path: '${Endpoints.momentDelete}/$id');
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> edit(String id, Map<String, dynamic> body) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.momentEdit,
        data: {'moment_id': id, ...body},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteDraft(String id) async {
    try {
      final res = await ApiService()
          .deleteData(path: '${Endpoints.momentDeleteDraft}/$id');
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> publish(String id) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.momentPublish,
        data: {'moment_id': id},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancel(String id) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.momentCancel,
        data: {'moment_id': id},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<ScheduledMoment>> fetchPublished() async {
    try {
      final res = await ApiService().getData(path: Endpoints.momentPublished);
      if (res['status'] == true &&
          res['data'] is Map &&
          res['data']['moments'] is List) {
        return (res['data']['moments'] as List)
            .map((e) => ScheduledMoment.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ScheduledMoment?> fetchDetails(String id) async {
    try {
      final res =
          await ApiService().getData(path: '${Endpoints.momentDetails}/$id');
      if (res['status'] == true && res['data'] is Map) {
        final momentJson = (res['data'] as Map)['moment'];
        if (momentJson != null) return ScheduledMoment.fromJson(momentJson);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> duplicate(String id) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.momentDuplicate,
        data: {'moment_id': id},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }
}
