import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String filePath;
  final String fileExtension;
  final String fileSize;
  final String? fileName;

  const DocumentViewerScreen({
    super.key,
    required this.filePath,
    required this.fileExtension,
    this.fileSize = '',
    this.fileName,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  int _pagesCount = 0;
  int _currentPage = 1;
  bool _pdfFailed = false;
  bool _sharing = false;

  bool get _isPdf => widget.fileExtension.toLowerCase() == 'pdf';

  bool get _isText => widget.fileExtension.toLowerCase() == 'txt';

  IconData _getFileIcon() {
    switch (widget.fileExtension.toLowerCase()) {
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
    switch (widget.fileExtension.toLowerCase()) {
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
    switch (widget.fileExtension.toLowerCase()) {
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
        return '${widget.fileExtension.toUpperCase()} File';
    }
  }

  String get _fileName {
    final explicit = widget.fileName;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final fromPath = widget.filePath.split(Platform.pathSeparator).last;
    return fromPath.isEmpty
        ? '.${widget.fileExtension.toUpperCase()}'
        : fromPath;
  }

  Future<void> _shareFile() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        CustomSnackbar.error(
            title: 'Error', message: 'File not found on device');
        return;
      }
      await SharePlus.instance.share(
        ShareParams(files: [
          XFile(file.path, mimeType: 'application/$widget.fileExtension')
        ]),
      );
    } catch (_) {
      CustomSnackbar.error(title: 'Error', message: 'Could not share file');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _openExternally() async {
    final result = await OpenFilex.open(widget.filePath);
    if (result.type != ResultType.done) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot open file'),
          content: Text(
            'No app found on your device for .${widget.fileExtension} files.',
            style: AppTextStyles.bodyMd,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got It'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPdf) return _buildPdfViewer();
    if (_isText) return _buildTextPreview();
    return _buildFileInfo();
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8.h,
      left: 8.w,
      right: 8.w,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_backspace,
                color: CustomColor.kTextOnDark,
                size: AppIcons.xxl.r,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm
                      .copyWith(color: CustomColor.kTextOnDark),
                ),
                Text(
                  _pagesCount > 0 ? '$_pagesCount pages' : _getFileTypeLabel(),
                  style: AppTextStyles.caption
                      .copyWith(color: CustomColor.kOverlay70),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _shareFile,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: _sharing
                  ? SizedBox(
                      width: AppIcons.xxl.r,
                      height: AppIcons.xxl.r,
                      child: const CircularProgressIndicator(
                        color: CustomColor.kTextOnDark,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.share_rounded,
                      color: CustomColor.kTextOnDark,
                      size: AppIcons.xxl.r,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Entrance(
          fade: true,
          slide: false,
          child: _pdfFailed
              ? _buildFileInfo(showOpenButton: true)
              : Stack(
                  children: [
                    PDFView(
                      filePath: widget.filePath,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      defaultPage: 0,
                      onRender: (pages) {
                        if (mounted) setState(() => _pagesCount = pages ?? 0);
                      },
                      onPageChanged: (page, total) {
                        if (mounted) {
                          setState(() {
                            _currentPage = (page ?? 0) + 1;
                            if (total != null) _pagesCount = total;
                          });
                        }
                      },
                      onError: (error) {
                        if (mounted) setState(() => _pdfFailed = true);
                      },
                    ),
                    _buildPdfPageIndicator(),
                    _buildTopBar(),
                  ],
                )),
    );
  }

  Widget _buildPdfPageIndicator() {
    final total = _pagesCount > 0 ? _pagesCount : 1;
    return Positioned(
      left: 0.w,
      right: 0.w,
      bottom: MediaQuery.of(context).padding.bottom + 24.h,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
          ),
          child: Text(
            '$_currentPage / $total',
            style:
                AppTextStyles.labelSm.copyWith(color: CustomColor.kTextOnDark),
          ),
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    final file = File(widget.filePath);
    return SafeArea(
      child: Scaffold(
        backgroundColor: CustomColor.kDarkSurface,
        body: Entrance(
            fade: true,
            slide: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg.w, vertical: AppSpacing.xs.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.keyboard_backspace,
                          color: CustomColor.kTextOnDark,
                          size: AppIcons.xxxl.r,
                        ),
                      ),
                      SizedBox(width: AppSpacing.lg.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSm
                                  .copyWith(color: CustomColor.kTextOnDark),
                            ),
                            Text(
                              _getFileTypeLabel(),
                              style: AppTextStyles.caption.copyWith(
                                  color: CustomColor.kTextOnDark
                                      .withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Share file',
                        onPressed: _shareFile,
                        icon: Icon(
                          Icons.share_rounded,
                          color: CustomColor.kTextOnDark,
                          size: AppIcons.xxl.r,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md.h),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: file.existsSync()
                          ? file.readAsString()
                          : Future.value(''),
                      builder: (context, snapshot) {
                        final content = snapshot.data ?? '';
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: CustomColor.kPrimaryColor,
                            ),
                          );
                        }
                        return Container(
                          width: double.maxFinite,
                          padding: EdgeInsets.all(AppSpacing.lg.r),
                          decoration: BoxDecoration(
                            color: CustomColor.kOverlay6,
                            borderRadius: BorderRadius.circular(AppRadius.md.r),
                          ),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              utf8.decode(content.codeUnits,
                                  allowMalformed: true),
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: CustomColor.kOverlay70),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                    child: SizedBox(
                      width: double.maxFinite,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: CustomColor.kPrimaryFill,
                          padding:
                              EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                        ),
                        onPressed: _openExternally,
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(
                          'Open with another app',
                          style: AppTextStyles.titleSm
                              .copyWith(color: CustomColor.kTextOnDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  Widget _buildFileInfo({bool showOpenButton = true}) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: CustomColor.kDarkSurface,
        body: Entrance(
            fade: true,
            slide: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg.w, vertical: AppSpacing.xs.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.keyboard_backspace,
                          color: CustomColor.kTextOnDark,
                          size: AppIcons.xxxl.r,
                        ),
                      ),
                      SizedBox(width: AppSpacing.lg.w),
                      Expanded(
                        child: Text(
                          _fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSm
                              .copyWith(color: CustomColor.kTextOnDark),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Share file',
                        onPressed: _shareFile,
                        icon: Icon(
                          Icons.share_rounded,
                          color: CustomColor.kTextOnDark,
                          size: AppIcons.xxl.r,
                        ),
                      ),
                    ],
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
                          _fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headingXl.copyWith(
                            color: CustomColor.kTextOnDark,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md.h),
                        Text(
                          _getFileTypeLabel(),
                          style: AppTextStyles.bodyMd.copyWith(
                              color: CustomColor.kTextOnDark
                                  .withValues(alpha: 0.6)),
                        ),
                        if (widget.fileSize.isNotEmpty) ...[
                          SizedBox(height: AppSpacing.xs.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl.w,
                                vertical: AppSpacing.xs.h),
                            decoration: BoxDecoration(
                              color: CustomColor.kTextOnDark
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md.r),
                            ),
                            child: Text(
                              widget.fileSize,
                              style: AppTextStyles.titleSm
                                  .copyWith(color: CustomColor.kPrimaryLight),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (showOpenButton)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                      child: SizedBox(
                        width: double.maxFinite,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: CustomColor.kPrimaryFill,
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                          ),
                          onPressed: _openExternally,
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: Text(
                            'Open File',
                            style: AppTextStyles.titleSm
                                .copyWith(color: CustomColor.kTextOnDark),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )),
      ),
    );
  }
}
