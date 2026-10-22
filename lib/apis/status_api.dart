import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/res/endpoints.dart';

class StatusApi {
  Future<MyUpdateData?> getMyUpdate() async {
    try {
      final res = await ApiService().getData(path: Endpoints.statusMyUpdate);
      if (res['status'] == true && res['data'] != null) {
        return MyUpdateData.fromJson(res['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<FriendUpdate>> fetchUpdates() async {
    try {
      // Statuses are short-lived (24h), so fetch every page — the story
      // strip must show all contacts, not just the first page.
      final all = <FriendUpdate>[];
      var page = 1;
      while (page <= 5) {
        final feed = await fetchFeed(page: page, perPage: 50);
        all.addAll(feed.updates);
        if (feed.updates.isEmpty || !feed.hasMore) break;
        page++;
      }
      return all;
    } catch (_) {
      return [];
    }
  }

  Future<StatusFeedData> fetchFeed({int page = 1, int perPage = 20}) async {
    try {
      final res = await ApiService().getData(
        path: Endpoints.statusFeed,
        queryParameters: {'page': page, 'per_page': perPage},
      );
      if (res['status'] == true) {
        return StatusFeedData.fromJson(res);
      }
      return StatusFeedData();
    } catch (_) {
      return StatusFeedData();
    }
  }

  Future<MyStatusesData?> fetchMyStatuses() async {
    try {
      final res = await ApiService().getData(path: Endpoints.statusMy);
      if (res['status'] == true && res['data'] != null) {
        return MyStatusesData.fromJson(res['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<StatusPrivacyData?> fetchPrivacy() async {
    try {
      final res = await ApiService().getData(path: Endpoints.statusPrivacy);
      if (res['status'] == true && res['data'] != null) {
        return StatusPrivacyData.fromJson(res['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> savePrivacy({
    required String privacy,
    List<int> exceptIds = const [],
    List<int> shareIds = const [],
  }) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusSavePrivacy,
        data: {
          'privacy': privacy,
          'except_ids': exceptIds,
          'share_ids': shareIds,
        },
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> report(String statusId, String reason) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusReport,
        data: {'status_id': statusId, 'reason': reason},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<int> share(String statusId) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusShare,
        data: {'status_id': statusId},
      );
      if (res['status'] == true && res['data'] != null) {
        return int.tryParse(res['data']['share_count']?.toString() ?? '0') ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> fetchShares(String statusId) async {
    try {
      final res = await ApiService().getData(
        path: '${Endpoints.statusShares}/$statusId',
      );
      if (res['status'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']['users'] ?? []);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> create(Map<String, dynamic> body,
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
        final res = await ApiService().post(
          path: Endpoints.statusCreate,
          data: formData,
        );
        if (res['status'] == true && res['data'] != null) {
          return res['data'];
        }
        return null;
      }
      final res = await ApiService().post(
        path: Endpoints.statusCreate,
        data: body,
      );
      if (res['status'] == true && res['data'] != null) {
        return res['data'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> edit(String updateId, String content) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusEdit,
        data: {'update_id': updateId, 'content': content},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> view(String statusId) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusView,
        data: {'status_id': statusId},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchViewers(String statusId) async {
    try {
      final res = await ApiService().getData(
        path: '${Endpoints.statusViewers}/$statusId',
      );
      if (res['status'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> changeAvailability(String status) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusChangeAvailability,
        data: {'status': status},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> archive(String updateId, bool archive) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusArchive,
        data: {'update_id': updateId, 'archive': archive ? '1' : '0'},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<StatusModel>> fetchArchived() async {
    try {
      final res =
          await ApiService().getData(path: Endpoints.statusArchivedList);
      if (res['status'] == true && res['data'] != null) {
        final List<dynamic> data = res['data'];
        return data.map((e) => StatusModel.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> delete(String id) async {
    try {
      final res = await ApiService().deleteData(
        path: '${Endpoints.statusDelete}/$id',
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> react(String statusId, String reaction) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusReact,
        data: {'status_id': statusId, 'reaction': reaction},
      );
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchReactions(String statusId) async {
    try {
      final res = await ApiService().getData(
        path: '${Endpoints.statusReactions}/$statusId',
      );
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> reply(String statusId, String message) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusReply,
        data: {'status_id': statusId, 'message': message},
      );
      return res;
    } catch (_) {
      return null;
    }
  }

  Future<List<StatusReply>> fetchReplies(String statusId) async {
    try {
      final res = await ApiService().getData(
        path: '${Endpoints.statusReplies}/$statusId',
      );
      if (res['status'] == true && res['data'] != null) {
        return (res['data'] as List)
            .map((e) => StatusReply.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> muteUser(String mutedUserId) async {
    try {
      final res = await ApiService().post(
        path: Endpoints.statusMute,
        data: {'muted_user_id': mutedUserId},
      );
      return res['status'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMutedList() async {
    try {
      final res = await ApiService().getData(path: Endpoints.statusMutedList);
      if (res['status'] == true && res['data'] != null) {
        return List<Map<String, dynamic>>.from(res['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> search({
    String? keyword,
    String? dateFrom,
    String? dateTo,
    String? mediaType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'per_page': perPage};
      if (keyword != null) params['keyword'] = keyword;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      if (mediaType != null) params['media_type'] = mediaType;
      final res = await ApiService().getData(
        path: Endpoints.statusSearch,
        queryParameters: params,
      );
      return res['status'] == true ? res['data'] : null;
    } catch (_) {
      return null;
    }
  }

  Future<StatusAnalytics?> fetchAnalytics() async {
    try {
      final res = await ApiService().getData(path: Endpoints.statusAnalytics);
      if (res['status'] == true && res['data'] != null) {
        return StatusAnalytics.fromJson(res['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadFile(File file) async {
    try {
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      final res = await ApiService().post(
        path: Endpoints.statusUpload,
        data: formData,
      );
      return res['status'] == true ? res['data'] : null;
    } catch (_) {
      return null;
    }
  }
}
