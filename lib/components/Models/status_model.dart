class StatusModel {
  final String? suId;
  final String? suUserId;
  final String? suContent;
  final String? suMediaUrl;
  final String? suMediaType;
  final String? suScheduleId;
  final String? suCreatedAt;
  final String? suExpiresAt;
  final String? suIsArchived;
  final String? suPrivacy;
  final String? suBgColor;
  final String? suFontStyle;
  final String? suTextColor;
  final String? suCaption;
  final String? suLocation;
  final String? suLink;
  final String? suMentions;
  final int? viewCount;
  final int? reactionCount;
  final int? replyCount;
  final int? shareCount;

  StatusModel({
    this.suId,
    this.suUserId,
    this.suContent,
    this.suMediaUrl,
    this.suMediaType,
    this.suScheduleId,
    this.suCreatedAt,
    this.suExpiresAt,
    this.suIsArchived,
    this.suPrivacy,
    this.suBgColor,
    this.suFontStyle,
    this.suTextColor,
    this.suCaption,
    this.suLocation,
    this.suLink,
    this.suMentions,
    this.viewCount,
    this.reactionCount,
    this.replyCount,
    this.shareCount,
  });

  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      suId: json['su_id']?.toString(),
      suUserId: json['su_user_id']?.toString(),
      suContent: json['su_content']?.toString(),
      suMediaUrl: json['su_media_url']?.toString(),
      suMediaType: json['su_media_type']?.toString(),
      suScheduleId: json['su_schedule_id']?.toString(),
      suCreatedAt: json['su_created_at']?.toString(),
      suExpiresAt: json['su_expires_at']?.toString(),
      suIsArchived: json['su_is_archived']?.toString(),
      suPrivacy: json['su_privacy']?.toString(),
      suBgColor: json['su_bg_color']?.toString(),
      suFontStyle: json['su_font_style']?.toString(),
      suTextColor: json['su_text_color']?.toString(),
      suCaption: json['su_caption']?.toString(),
      suLocation: json['su_location']?.toString(),
      suLink: json['su_link']?.toString(),
      suMentions: json['su_mentions']?.toString(),
      viewCount: json['view_count'] is int
          ? json['view_count']
          : int.tryParse(json['view_count']?.toString() ?? ''),
      reactionCount: json['reaction_count'] is int
          ? json['reaction_count']
          : int.tryParse(json['reaction_count']?.toString() ?? ''),
      replyCount: json['reply_count'] is int
          ? json['reply_count']
          : int.tryParse(json['reply_count']?.toString() ?? ''),
      shareCount: json['share_count'] is int
          ? json['share_count']
          : int.tryParse(json['share_count']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'su_id': suId,
      'su_user_id': suUserId,
      'su_content': suContent,
      'su_media_url': suMediaUrl,
      'su_media_type': suMediaType,
      'su_schedule_id': suScheduleId,
      'su_created_at': suCreatedAt,
      'su_expires_at': suExpiresAt,
      'su_is_archived': suIsArchived,
      'su_privacy': suPrivacy,
      'su_bg_color': suBgColor,
      'su_font_style': suFontStyle,
      'su_text_color': suTextColor,
      'su_caption': suCaption,
      'su_location': suLocation,
      'su_link': suLink,
      'su_mentions': suMentions,
      'view_count': viewCount,
      'reaction_count': reactionCount,
      'reply_count': replyCount,
      'share_count': shareCount,
    };
  }

  bool get isExpired {
    final expires = StatusModel.parseServerDate(suExpiresAt);
    if (expires == null) return false;
    return expires.isBefore(DateTime.now().toUtc());
  }

  /// Parses backend `'Y-m-d H:i:s'` timestamps as UTC. CI4 forces
  /// `date_default_timezone_set('UTC')` on every request
  /// (system/CodeIgniter.php:217) and the API sends naive datetime strings,
  /// so treating them as phone-local time skews the 24h expiry by the phone's
  /// UTC offset (stories can linger for hours — or vanish early).
  static DateTime? parseServerDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final cleaned = raw.trim().replaceFirst(' ', 'T');
    final parsed = DateTime.tryParse(cleaned);
    if (parsed == null) return null;
    return DateTime.utc(parsed.year, parsed.month, parsed.day, parsed.hour,
        parsed.minute, parsed.second);
  }
}

class FriendUpdate {
  final StatusModel? update;
  final Map<String, dynamic>? author;
  final int? viewCount;
  final int? shareCount;
  final int? replyCount;
  final bool? viewed;
  final String? myReaction;
  final bool? myReply;

  FriendUpdate({
    this.update,
    this.author,
    this.viewCount,
    this.shareCount,
    this.replyCount,
    this.viewed,
    this.myReaction,
    this.myReply,
  });

  factory FriendUpdate.fromJson(Map<String, dynamic> json) {
    return FriendUpdate(
      update:
          json['update'] != null ? StatusModel.fromJson(json['update']) : null,
      author: json['author'],
      viewCount: json['view_count'] is int
          ? json['view_count']
          : int.tryParse(json['view_count']?.toString() ?? '0'),
      shareCount: json['share_count'] is int
          ? json['share_count']
          : int.tryParse(json['share_count']?.toString() ?? '0'),
      replyCount: json['reply_count'] is int
          ? json['reply_count']
          : int.tryParse(json['reply_count']?.toString() ?? '0'),
      viewed: json['viewed'] == null
          ? null
          : (json['viewed'] == true || json['viewed'] == '1'),
      myReaction: json['my_reaction']?.toString(),
      myReply: json['my_reply'] == null
          ? null
          : (json['my_reply'] == true || json['my_reply'] == '1'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'update': update?.toJson(),
      'author': author,
      'view_count': viewCount,
      'share_count': shareCount,
      'reply_count': replyCount,
      'viewed': viewed,
      'my_reaction': myReaction,
      'my_reply': myReply,
    };
  }

  /// True when the current user already interacted with this status
  /// (replied or reacted) — drives the WhatsApp-style highlight in the feed.
  bool get hasInteracted => myReply == true || myReaction != null;
}

class StatusFeedData {
  final List<FriendUpdate> updates;
  final int page;
  final int perPage;
  final int total;
  final bool hasMore;

  StatusFeedData({
    this.updates = const [],
    this.page = 1,
    this.perPage = 20,
    this.total = 0,
    this.hasMore = false,
  });

  factory StatusFeedData.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return StatusFeedData(
      updates: (json['data'] as List? ?? [])
          .map((e) => FriendUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: meta['page'] ?? 1,
      perPage: meta['per_page'] ?? 20,
      total: meta['total'] ?? 0,
      hasMore: meta['has_more'] == true,
    );
  }
}

class MyStatusesData {
  final Map<String, dynamic>? user;
  final List<StatusModel> statuses;
  final Map<String, dynamic>? privacy;

  MyStatusesData({this.user, this.statuses = const [], this.privacy});

  factory MyStatusesData.fromJson(Map<String, dynamic> json) {
    return MyStatusesData(
      user: json['user'],
      statuses: (json['statuses'] as List? ?? [])
          .map((e) => StatusModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      privacy: json['privacy'],
    );
  }
}

class StatusPrivacyData {
  final String? privacy;
  final List<int> exceptIds;
  final List<int> shareIds;

  StatusPrivacyData(
      {this.privacy, this.exceptIds = const [], this.shareIds = const []});

  factory StatusPrivacyData.fromJson(Map<String, dynamic> json) {
    return StatusPrivacyData(
      privacy: json['privacy']?.toString(),
      exceptIds: (json['except_ids'] as List? ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList(),
      shareIds: (json['share_ids'] as List? ?? [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacy': privacy,
      'except_ids': exceptIds,
      'share_ids': shareIds,
    };
  }
}

class MyUpdateData {
  final Map<String, dynamic>? user;
  final AvailabilityModel? availability;
  final StatusModel? latestUpdate;

  MyUpdateData({this.user, this.availability, this.latestUpdate});

  factory MyUpdateData.fromJson(Map<String, dynamic> json) {
    return MyUpdateData(
      user: json['user'],
      availability: json['availability'] != null
          ? AvailabilityModel.fromJson(json['availability'])
          : null,
      latestUpdate: json['latest_update'] != null
          ? StatusModel.fromJson(json['latest_update'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user,
      'availability': availability?.toJson(),
      'latest_update': latestUpdate?.toJson(),
    };
  }
}

class ScheduledMoment {
  final String? smId;
  final String? smUserId;
  final String? smImage;
  final String? smVideo;
  final String? smCaption;
  final String? smScheduledDatetime;
  final int? smExpiryHours;
  final String? smPublishedDatetime;
  final String? smVisibility;
  final String? smStatus;
  final String? smCreatedAt;
  final int? smDraft;

  ScheduledMoment({
    this.smId,
    this.smUserId,
    this.smImage,
    this.smVideo,
    this.smCaption,
    this.smScheduledDatetime,
    this.smExpiryHours,
    this.smPublishedDatetime,
    this.smVisibility,
    this.smStatus,
    this.smCreatedAt,
    this.smDraft,
  });

  factory ScheduledMoment.fromJson(Map<String, dynamic> json) {
    return ScheduledMoment(
      smId: json['sm_id']?.toString(),
      smUserId: json['sm_user_id']?.toString(),
      smImage: json['sm_image']?.toString(),
      smVideo: json['sm_video']?.toString(),
      smCaption: json['sm_caption']?.toString(),
      smScheduledDatetime: json['sm_scheduled_datetime']?.toString(),
      smExpiryHours: json['sm_expiry_hours'] is int
          ? json['sm_expiry_hours']
          : int.tryParse(json['sm_expiry_hours']?.toString() ?? ''),
      smPublishedDatetime: json['sm_published_datetime']?.toString(),
      smVisibility: json['sm_visibility']?.toString(),
      smStatus: json['sm_status']?.toString(),
      smCreatedAt: json['sm_created_at']?.toString(),
      smDraft: json['sm_draft'] is int
          ? json['sm_draft']
          : int.tryParse(json['sm_draft']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sm_id': smId,
      'sm_user_id': smUserId,
      'sm_image': smImage,
      'sm_video': smVideo,
      'sm_caption': smCaption,
      'sm_scheduled_datetime': smScheduledDatetime,
      'sm_expiry_hours': smExpiryHours,
      'sm_published_datetime': smPublishedDatetime,
      'sm_visibility': smVisibility,
      'sm_status': smStatus,
      'sm_created_at': smCreatedAt,
      'sm_draft': smDraft,
    };
  }

  String? get smContent => smCaption;

  String? get smMediaUrl {
    final image = smImage;
    if (image != null && image.isNotEmpty) return image;
    return smVideo;
  }

  String get smMediaType {
    if (smImage != null && smImage!.isNotEmpty) return 'image';
    if (smVideo != null && smVideo!.isNotEmpty) return 'video';
    return 'text';
  }

  /// Publish time as epoch seconds (null when not scheduled yet).
  int? get scheduledEpoch {
    final raw = smScheduledDatetime;
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(
        raw.contains('T') ? raw : '${raw.replaceFirst(' ', 'T')}Z');
    if (dt == null) return null;
    return dt.millisecondsSinceEpoch ~/ 1000;
  }

  bool get isDraft => smStatus == 'draft' || (smDraft ?? 0) == 1;
  bool get isPending => smStatus == 'scheduled';
  bool get isPublished => smStatus == 'published';
  bool get isExpired => smStatus == 'expired';
}

class StatusReaction {
  final String? srId;
  final String? srStatusId;
  final String? srUserId;
  final String? srReaction;
  final String? srCreatedAt;

  StatusReaction({
    this.srId,
    this.srStatusId,
    this.srUserId,
    this.srReaction,
    this.srCreatedAt,
  });

  factory StatusReaction.fromJson(Map<String, dynamic> json) {
    return StatusReaction(
      srId: json['sr_id']?.toString(),
      srStatusId: json['sr_status_id']?.toString(),
      srUserId: json['sr_user_id']?.toString(),
      srReaction: json['sr_reaction']?.toString(),
      srCreatedAt: json['sr_created_at']?.toString(),
    );
  }
}

class StatusReply {
  final String? srpId;
  final String? srpStatusId;
  final String? srpUserId;
  final String? srpMessage;
  final String? srpCreatedAt;
  final Map<String, dynamic>? author;

  StatusReply({
    this.srpId,
    this.srpStatusId,
    this.srpUserId,
    this.srpMessage,
    this.srpCreatedAt,
    this.author,
  });

  factory StatusReply.fromJson(Map<String, dynamic> json) {
    final reply = json['reply'] as Map<String, dynamic>? ?? json;
    return StatusReply(
      srpId: reply['srp_id']?.toString(),
      srpStatusId: reply['srp_status_id']?.toString(),
      srpUserId: reply['srp_user_id']?.toString(),
      srpMessage: reply['srp_message']?.toString(),
      srpCreatedAt: reply['srp_created_at']?.toString(),
      author: json['author'],
    );
  }
}

class StatusAnalytics {
  final int totalUpdates;
  final int totalViews;
  final int totalReactions;
  final int totalReplies;
  final int totalShares;
  final double reach;
  final double completionRate;
  final List<Map<String, dynamic>> updates;

  StatusAnalytics({
    this.totalUpdates = 0,
    this.totalViews = 0,
    this.totalReactions = 0,
    this.totalReplies = 0,
    this.totalShares = 0,
    this.reach = 0,
    this.completionRate = 0,
    this.updates = const [],
  });

  factory StatusAnalytics.fromJson(Map<String, dynamic> json) {
    return StatusAnalytics(
      totalUpdates: json['total_updates'] ?? 0,
      totalViews: json['total_views'] ?? 0,
      totalReactions: json['total_reactions'] ?? 0,
      totalReplies: json['total_replies'] ?? 0,
      totalShares: json['total_shares'] ?? 0,
      reach: (json['reach'] ?? 0).toDouble(),
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
      updates: List<Map<String, dynamic>>.from(json['updates'] ?? []),
    );
  }
}

class AvailabilityModel {
  final String? uaId;
  final String? uaUserId;
  final String? uaStatus;
  final String? uaUpdatedAt;

  AvailabilityModel({
    this.uaId,
    this.uaUserId,
    this.uaStatus,
    this.uaUpdatedAt,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      uaId: json['ua_id']?.toString(),
      uaUserId: json['ua_user_id']?.toString(),
      uaStatus: json['ua_status']?.toString(),
      uaUpdatedAt: json['ua_updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ua_id': uaId,
      'ua_user_id': uaUserId,
      'ua_status': uaStatus,
      'ua_updated_at': uaUpdatedAt,
    };
  }
}
