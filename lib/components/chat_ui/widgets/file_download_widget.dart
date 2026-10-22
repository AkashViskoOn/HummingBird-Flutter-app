import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/chats/chat_screens/document_viewer_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// WhatsApp-style document bubble: file icon, real file name, size and
/// download/open states.
class FileDownloadWidget extends StatelessWidget {
  final String mediaUrl;
  final String mediaId;
  final String roomId;
  final String mediaKey;

  const FileDownloadWidget({
    super.key,
    required this.mediaUrl,
    required this.mediaId,
    required this.roomId,
    required this.mediaKey,
  });

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'ogg':
        return Icons.audiotrack_rounded;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.movie_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  String _fileName(String extension) {
    final key = mediaKey.trim();
    if (key.isNotEmpty && !key.startsWith('http')) {
      final clean = key.replaceAll('\\', '/');
      final last = clean.split('/').last;
      if (last.isNotEmpty && last != '.') return last;
    }
    return 'Document.$extension';
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final birdController = Get.find<BirdController>();
    final fullUrl = AppHelper.resolveMediaUrl(mediaUrl);
    final extension = AppHelper.getFileExtension(fullUrl);
    final fileIcon = _getFileIcon(extension);
    final fileColor =
        AppHelper.mediaAccentColor(fileType: '2', mediaUrl: fullUrl);
    final fileName = _fileName(extension);

    return Container(
      constraints: BoxConstraints(maxWidth: 230.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        border: Border.all(
          color: fileColor.withValues(alpha: 0.28),
          width: 1,
        ),
        color: CustomColor.kWhite,
        boxShadow: [
          BoxShadow(
            color: CustomColor.kScrim20,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final isDownloading =
            birdController.downloadingMediaMap[mediaId] == true;
        final downloadProgress =
            birdController.downloadingMediaMap['${mediaId}_progress'];
        final savedMedia = LocalDatabase.getMedia(mediaId);

        String sizeLabel = '';
        if (savedMedia?.mediaPath?.isNotEmpty == true) {
          try {
            final file = File(savedMedia!.mediaPath!);
            if (file.existsSync()) sizeLabel = _formatBytes(file.lengthSync());
          } catch (_) {}
        }

        return InkWell(
          onTap: () async {
            if (isDownloading) {
              chatController.cancelDownload(mediaId);
              return;
            }
            if (savedMedia != null) {
              final path = savedMedia.mediaPath ?? '';
              if (path.isNotEmpty) {
                Get.to(() => DocumentViewerScreen(
                      filePath: path,
                      fileExtension: extension,
                      fileSize: sizeLabel,
                    ));
              }
            } else {
              chatController.downloadMedia(fullUrl, mediaId, roomId, '2');
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          child: Padding(
            padding: EdgeInsets.all(10.r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: fileColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: isDownloading
                      ? Center(
                          child: SizedBox(
                            width: 22.r,
                            height: 22.r,
                            child: CircularProgressIndicator(
                              color: fileColor,
                              strokeWidth: 2,
                              value: (downloadProgress is double)
                                  ? downloadProgress.clamp(0.0, 1.0)
                                  : null,
                            ),
                          ),
                        )
                      : Icon(
                          savedMedia != null
                              ? Icons.file_open_rounded
                              : fileIcon,
                          color: fileColor,
                          size: 24.r,
                        ),
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDownloading
                            ? 'Downloading...'
                            : savedMedia != null
                                ? 'Open'
                                : fileName,
                        style: AppTextStyles.label.copyWith(
                          color: CustomColor.kTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: fileColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xs.r),
                            ),
                            child: Text(
                              extension.toUpperCase(),
                              style: AppTextStyles.labelSm.copyWith(
                                color: fileColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 9.sp,
                              ),
                            ),
                          ),
                          if (sizeLabel.isNotEmpty) ...[
                            SizedBox(width: 5.w),
                            Text(
                              sizeLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: CustomColor.kTextSecondary,
                              ),
                            ),
                          ],
                          if (isDownloading && downloadProgress is double)
                            Text(
                              '  ${(downloadProgress * 100).toInt()}%',
                              style: AppTextStyles.caption.copyWith(
                                color: fileColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isDownloading && savedMedia == null)
                  Padding(
                    padding: EdgeInsets.only(left: 6.w),
                    child: Icon(
                      Icons.download_rounded,
                      color: fileColor,
                      size: 20.r,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
