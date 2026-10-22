import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/chat_ui/widgets/file_download_widget.dart';
import 'package:humming_bird/components/chat_ui/widgets/image_view_widget.dart';
import 'package:humming_bird/components/chat_ui/widgets/video_view_widget.dart';
import 'package:humming_bird/components/chat_ui/widgets/voice_message_widget.dart';
import 'package:humming_bird/components/contact/contact_profile_sheet.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AppHelper {
  /// Resolves a possibly-relative media path to an absolute URL.
  /// Safe against double-prefixing when the backend already returns an
  /// absolute URL.
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '${Endpoints.mediaBaseUrl}$path';
    }
    return '${Endpoints.mediaBaseUrl}/$path';
  }

  static String formatTime(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final parsed = DateTime.parse(time);
      return DateFormat('h:mm a').format(parsed);
    } catch (_) {
      return time;
    }
  }

  /// Parses a backend datetime string into device-local time.
  ///
  /// The backend stores all timestamps in UTC (App.php `appTimezone = 'UTC'`)
  /// as `YYYY-MM-DD HH:MM:SS` with no zone suffix. `DateTime.parse` treats a
  /// zoneless string as local, so relative labels ("5h ago") were off by the
  /// device's UTC offset. This helper reads the value as UTC and converts it
  /// to the device's local zone. Values that already carry an explicit zone
  /// (`Z` or `±HH:MM`) are honoured as-is.
  static DateTime? parseServerUtc(String? value) {
    if (value == null) return null;
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(raw);
    final parsed =
        DateTime.tryParse(hasZone ? raw : '${raw.replaceFirst(' ', 'T')}Z');
    return parsed?.toLocal();
  }

  /// Normalizes a stored date of birth to `DD/MM/YYYY` for display.
  /// Accepts legacy `yyyy-MM-dd` DB values as well as already-formatted
  /// `dd/MM/yyyy` strings; anything unparseable is returned unchanged.
  static String formatDobForDisplay(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '';
    final iso = DateTime.tryParse(value);
    if (iso != null) return DateFormat('dd/MM/yyyy').format(iso);
    try {
      final dm = DateFormat('dd/MM/yyyy').parseStrict(value);
      return DateFormat('dd/MM/yyyy').format(dm);
    } catch (_) {
      return value;
    }
  }

  /// Formats the actual sent time of a message. Prefers the server epoch
  /// (m_epoch_time), falling back to created/updated timestamps.
  static String formatSentTime(dynamic message) {
    final epoch = int.tryParse(message?.mEpochTime?.toString() ?? '');
    if (epoch != null && epoch > 0) {
      return DateFormat('h:mm a')
          .format(DateTime.fromMillisecondsSinceEpoch(epoch * 1000));
    }
    final createdAt = message?.mCreatedAt?.toString();
    if (createdAt != null && createdAt.isNotEmpty) {
      return formatTime(createdAt);
    }
    final updatedAt = message?.mUpdatedAt?.toString();
    if (updatedAt != null && updatedAt.isNotEmpty) {
      return formatTime(updatedAt);
    }
    return '';
  }

  /// Returns an ISO-8601 timestamp of when a message was actually sent.
  static String getSentDate(dynamic message) {
    final epoch = int.tryParse(message?.mEpochTime?.toString() ?? '');
    if (epoch != null && epoch > 0) {
      return DateTime.fromMillisecondsSinceEpoch(epoch * 1000)
          .toIso8601String();
    }
    final createdAt = message?.mCreatedAt?.toString();
    if (createdAt != null && createdAt.isNotEmpty) return createdAt;
    final updatedAt = message?.mUpdatedAt?.toString();
    if (updatedAt != null && updatedAt.isNotEmpty) return updatedAt;
    return '';
  }

  static String formatRoomsTime(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final parsed = DateTime.parse(time);
      final now = DateTime.now();
      final diff = now.difference(parsed);

      if (diff.inDays == 0) {
        return DateFormat('h:mm a').format(parsed);
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return DateFormat('EEEE').format(parsed);
      } else {
        return DateFormat('dd/MM/yy').format(parsed);
      }
    } catch (_) {
      return time;
    }
  }

  /// Formats the chat-list timestamp for a message. Prefers the server
  /// update time and falls back to the create time so rooms whose
  /// m_updated_at column is NULL still render a time.
  static String formatRoomsTimeFromMessage(dynamic message) {
    if (message == null) return '';
    final updatedAt = message?.mUpdatedAt?.toString() ?? '';
    final createdAt = message?.mCreatedAt?.toString() ?? '';
    if (updatedAt.isNotEmpty) return formatRoomsTime(updatedAt);
    if (createdAt.isNotEmpty) return formatRoomsTime(createdAt);
    return '';
  }

  static String formatDateTimeFromEpoch(String epoch, String format) {
    try {
      final parsed =
          DateTime.fromMillisecondsSinceEpoch(int.parse(epoch) * 1000);
      return DateFormat(format).format(parsed);
    } catch (_) {
      return epoch;
    }
  }

  static String getTimeStamp(String time) {
    try {
      final parsed = DateTime.parse(time);
      final now = DateTime.now();
      if (parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (parsed.year == yesterday.year &&
          parsed.month == yesterday.month &&
          parsed.day == yesterday.day) {
        return 'Yesterday';
      }
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return time;
    }
  }

  static String getDate(String? time) {
    if (time == null || time.isEmpty) return '';
    try {
      final parsed = DateTime.parse(time);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return time;
    }
  }

  static String getFormattedStringFromEpoch(String epoch) {
    try {
      final parsed =
          DateTime.fromMillisecondsSinceEpoch(int.parse(epoch) * 1000);
      return parsed.toIso8601String();
    } catch (_) {
      return epoch;
    }
  }

  /// Returns `yyyy-MM-dd` from epoch seconds.
  static String getFormattedDateFromEpoch(int epochSeconds) {
    try {
      final parsed = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      return '';
    }
  }

  static String getMediaName({required String fileType}) {
    switch (fileType.trim()) {
      case '1':
        return '📷 Photo';
      case '2':
      case '5':
        return '📄 Document';
      case '3':
        return '🎵 Audio';
      case '4':
        return '🎬 Video';
      case '6':
        return '👤 Contact';
      default:
        return '📎 File';
    }
  }

  /// Shared media-type accent color used by every media bubble (doc, audio,
  /// video, reply thumbs). Type recognisable, high contrast on both light and
  /// dark bubbles.
  static Color mediaAccentColor({
    required String fileType,
    String mediaUrl = '',
  }) {
    switch (fileType.trim()) {
      case '2':
      case '5':
        switch (AppHelper.getFileExtension(mediaUrl).toLowerCase()) {
          case 'pdf':
            return CustomColor.kDangerRed;
          case 'xls':
          case 'xlsx':
            return CustomColor.kSuccess;
          case 'ppt':
          case 'pptx':
            return CustomColor.kWarning;
          case 'zip':
          case 'rar':
          case 'tar':
          case 'gz':
            return CustomColor.kBrandPurple;
          case 'doc':
          case 'docx':
            return CustomColor.kBrandAccent;
          default:
            return CustomColor.kInfo;
        }
      case '3':
        return CustomColor.kPrimaryColor;
      case '4':
        return CustomColor.kPrimaryMedium;
      default:
        return CustomColor.kTextSecondary;
    }
  }

  /// Shared media-type icon used by reply thumbs and fallbacks, so every
  /// media type gets a recognisable icon everywhere it appears.
  static IconData mediaTypeIcon({required String fileType}) {
    switch (fileType.trim()) {
      case '2':
      case '5':
        return Icons.insert_drive_file_rounded;
      case '3':
        return Icons.mic_rounded;
      case '4':
        return Icons.videocam_rounded;
      case '1':
        return Icons.image_rounded;
      case '6':
        return Icons.person_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  static Widget checkFileType({
    required String mediaId,
    required String roomId,
    required String mediaUrl,
    required String fileType,
    required String msg,
    String? messageId,
  }) {
    switch (fileType.trim()) {
      case '1':
        return ImageViewWidget(
          imageUrl: mediaUrl,
          mediaId: mediaId,
          roomId: roomId,
          messageId: messageId ?? mediaId,
        );
      case '2':
      case '5':
        return FileDownloadWidget(
          mediaUrl: mediaUrl,
          mediaId: mediaId,
          roomId: roomId,
          mediaKey: msg,
        );
      case '3':
        return VoiceMessageWidget(
          mediaUrl: mediaUrl,
          mediaId: mediaId,
          roomId: roomId,
          audioKey: msg,
        );
      case '4':
        return VideoViewWidget(
          videoUrl: mediaUrl,
          mediaId: mediaId,
          roomId: roomId,
          videoKey: msg,
          messageId: messageId ?? mediaId,
        );
      case '6':
        try {
          final contactData = jsonDecode(msg);
          final contactName =
              (contactData['name'] as String?)?.trim() ?? 'Unknown';
          final contactNumber = (contactData['number'] as String?) ?? '';
          final contactProfile = (contactData['profile'] as String?) ?? '';
          final user = ContactProfileSheet.findUserByNumber(contactNumber);
          final avatar = ContactProfileSheet.avatarProvider(
              contactProfile.isEmpty ? null : contactProfile, user);
          final isRegistered = user != null;
          return GestureDetector(
            onTap: () => ContactProfileSheet.openFromJson(msg),
            child: Padding(
              padding: EdgeInsets.all(6.r),
              child: Container(
                width: 232.w,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: CustomColor.kTextOnDark,
                  borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                  border: Border.all(color: CustomColor.kScrim20),
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kScrim20,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 21.r,
                      backgroundColor: CustomColor.kPrimaryLight,
                      backgroundImage: avatar,
                      onBackgroundImageError: (_, __) {},
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  contactName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleSm.copyWith(
                                      color: CustomColor.kTextPrimary),
                                ),
                              ),
                              if (isRegistered) ...[
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.verified_rounded,
                                  size: 14.r,
                                  color: CustomColor.kPrimaryColor,
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            contactNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle
                                .copyWith(color: CustomColor.kTextSecondary),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            isRegistered ? 'Humming Bird Contact' : 'Contact',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption
                                .copyWith(color: CustomColor.kTextTertiary),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: CustomColor.kTextTertiary,
                      size: 20.r,
                    ),
                  ],
                ),
              ),
            ),
          );
        } catch (_) {
          return Text(
            '👤 Contact',
            style: AppTextStyles.bodyMd,
          );
        }
      default:
        return Text(
          msg,
          style: AppTextStyles.bodyMd,
        );
    }
  }

  /// Sends the read/delivery tick for the caller's own bubble.
  /// [color] overrides the default icon color — the sent bubble is a blue
  /// gradient, so callers should pass a light color there (the old default
  /// `kTextTertiary` / `kPrimaryColor` (#2192CF) is nearly invisible on it).
  static Widget checkMessageStatus(String status, {Color? color}) {
    final tint = color ?? CustomColor.kTextTertiary;
    switch (status) {
      case '0':
        return Icon(Icons.schedule, size: 15.r, color: tint);
      case '1':
        return Icon(Icons.check, size: 15.r, color: tint);
      case '2':
        return Icon(Icons.done_all, size: 15.r, color: tint);
      case '3':
        return Icon(Icons.done_all,
            size: 15.r, color: color ?? CustomColor.kPrimaryColor);
      default:
        return Icon(Icons.check, size: 15.r, color: tint);
    }
  }

  static int convertScheduledTimeToEpoch(DateTime? dateTime) {
    if (dateTime == null) return 0;
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }

  static String getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final dot = path.lastIndexOf('.');
      if (dot != -1 && dot < path.length - 1) return path.substring(dot + 1);
    } catch (_) {}
    return 'bin';
  }

  static String getMediaPathName(String mediaType) {
    switch (mediaType.trim()) {
      case '1':
        return 'Images';
      case '2':
      case '5':
        return 'Documents';
      case '3':
        return 'Audio';
      case '4':
        return 'Videos';
      default:
        return 'Files';
    }
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static String formatDateTime(DateTime dateTime, String format) {
    return DateFormat(format).format(dateTime);
  }

  static String formatDateTimeFromEpoch2(String epoch) {
    try {
      final parsed =
          DateTime.fromMillisecondsSinceEpoch(int.parse(epoch) * 1000);
      final now = DateTime.now();
      final diff = now.difference(parsed);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('dd MMM').format(parsed);
    } catch (_) {
      return epoch;
    }
  }
}
