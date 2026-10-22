import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/chat_ui/chat_text_field.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';

class DocumentPreviewScreen extends StatelessWidget {
  final String fileExtension;
  final String fileSize;
  final bool isSchedule;
  const DocumentPreviewScreen({
    super.key,
    required this.fileExtension,
    required this.fileSize,
    required this.isSchedule,
  });

  IconData _getFileIcon() {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'flac':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor() {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return CustomColor.kDangerRed;
      case 'doc':
      case 'docx':
        return CustomColor.kBrandIndigo;
      case 'xls':
      case 'xlsx':
        return CustomColor.kSuccessDeep;
      case 'ppt':
      case 'pptx':
        return CustomColor.kDangerRed;
      case 'zip':
      case 'rar':
      case '7z':
        return CustomColor.kWarning;
      case 'txt':
        return CustomColor.kSlate500;
      default:
        return CustomColor.kPrimaryMedium;
    }
  }

  String _getFileTypeLabel() {
    switch (fileExtension.toLowerCase()) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xls':
      case 'xlsx':
        return 'Excel Spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'PowerPoint Presentation';
      case 'zip':
      case 'rar':
      case '7z':
        return 'Archive';
      case 'txt':
        return 'Text File';
      default:
        return '${fileExtension.toUpperCase()} File';
    }
  }

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return SafeArea(
      child: Scaffold(
        backgroundColor: CustomColor.kDarkSurface,
        body: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.w, vertical: AppSpacing.xs.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(
                  Icons.keyboard_backspace,
                  color: CustomColor.kTextOnDark,
                  size: AppIcons.xxxl.r,
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120.r,
                      height: 120.r,
                      decoration: BoxDecoration(
                        color: _getFileColor().withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppRadius.rounded.r),
                      ),
                      child: Icon(
                        _getFileIcon(),
                        size: AppIcons.huge.r,
                        color: _getFileColor(),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    Text(
                      '.${fileExtension.toUpperCase()}',
                      style: AppTextStyles.headingXl
                          .copyWith(color: CustomColor.kTextOnDark),
                    ),
                    SizedBox(height: AppSpacing.md.h),
                    Text(
                      _getFileTypeLabel(),
                      style: AppTextStyles.bodyMd.copyWith(
                          color:
                              CustomColor.kTextOnDark.withValues(alpha: 0.6)),
                    ),
                    SizedBox(height: AppSpacing.xs.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl.w,
                          vertical: AppSpacing.xs.h),
                      decoration: BoxDecoration(
                        color: CustomColor.kOverlay8,
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                      ),
                      child: Text(
                        fileSize,
                        style: AppTextStyles.titleSm
                            .copyWith(color: CustomColor.kPrimaryLight),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
                child: Row(
                  children: [
                    const Flexible(child: ChatTextField()),
                    SizedBox(width: AppSpacing.xs.w),
                    GestureDetector(
                      onTap: () {
                        chatController.sendMedia(
                          messageType: 2,
                          includeText: true,
                          isScheduled: isSchedule,
                        );
                        Get.back();
                      },
                      child: Container(
                        padding: EdgeInsets.all(5.r),
                        decoration: const BoxDecoration(
                          color: CustomColor.k2LightsecondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.send,
                            size: AppIcons.big.r,
                            color: CustomColor.kDarkPrimaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
            ],
          ),
        ),
      ),
    );
  }
}
