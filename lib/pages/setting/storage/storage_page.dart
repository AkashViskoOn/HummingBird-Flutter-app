import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/settings/setting_tile.dart';
import 'package:humming_bird/pages/media/gallery_page.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> with WidgetsBindingObserver {
  bool _isCalculating = true;
  bool _hasCalculatedOnce = false;

  double _totalSize = 0;
  double _imagesSize = 0;
  int _imagesCount = 0;
  double _videosSize = 0;
  int _videosCount = 0;
  double _documentsSize = 0;
  int _documentsCount = 0;
  double _voiceSize = 0;
  int _voiceCount = 0;
  double _otherSize = 0;
  double _cacheSize = 0;
  double _dbSize = 0;

  final GetStorage _getStorage = GetStorage();

  bool _autoDownloadMobile = true;
  bool _autoDownloadWifi = true;
  bool _autoDownloadRoaming = true;

  static const _imageExts = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'};
  static const _videoExts = {'.mp4', '.mov', '.avi', '.mkv', '.webm'};
  static const _docExts = {
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx'
  };
  static const _audioExts = {'.mp3', '.wav', '.aac', '.ogg', '.m4a'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadToggles();
    _calculateStorage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _calculateStorage();
    }
  }

  void _loadToggles() {
    setState(() {
      _autoDownloadMobile =
          _getStorage.read<bool>('auto_download_mobile') ?? true;
      _autoDownloadWifi = _getStorage.read<bool>('auto_download_wifi') ?? true;
      _autoDownloadRoaming =
          _getStorage.read<bool>('auto_download_roaming') ?? true;
    });
  }

  Future<int> _dirSizeBytes(Directory dir) async {
    int total = 0;
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }

  Future<void> _calculateStorage() async {
    if (!_hasCalculatedOnce && mounted) {
      setState(() => _isCalculating = true);
    }

    double imgS = 0, vidS = 0, docS = 0, audS = 0, othS = 0;
    int imgC = 0, vidC = 0, docC = 0, audC = 0;

    try {
      final docs = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${docs.path}/Humming-Bird');
      if (await mediaDir.exists()) {
        await for (final entity
            in mediaDir.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          final name = entity.uri.pathSegments.last.toLowerCase();
          final dot = name.lastIndexOf('.');
          final ext = dot == -1 ? '' : name.substring(dot);
          int size = 0;
          try {
            size = await entity.length();
          } catch (_) {
            continue;
          }
          if (_imageExts.contains(ext)) {
            imgS += size;
            imgC++;
          } else if (_videoExts.contains(ext)) {
            vidS += size;
            vidC++;
          } else if (_docExts.contains(ext)) {
            docS += size;
            docC++;
          } else if (_audioExts.contains(ext)) {
            audS += size;
            audC++;
          } else {
            othS += size;
          }
        }
      }

      final hiveDir = Directory('${docs.path}/hive');
      if (await hiveDir.exists()) {
        _dbSize = (await _dirSizeBytes(hiveDir)).toDouble();
      } else {
        _dbSize = 0;
      }
    } catch (_) {}

    try {
      final temp = await getTemporaryDirectory();
      if (await temp.exists()) {
        _cacheSize = (await _dirSizeBytes(temp)).toDouble();
      } else {
        _cacheSize = 0;
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _imagesSize = imgS.toDouble();
      _imagesCount = imgC;
      _videosSize = vidS.toDouble();
      _videosCount = vidC;
      _documentsSize = docS.toDouble();
      _documentsCount = docC;
      _voiceSize = audS.toDouble();
      _voiceCount = audC;
      _otherSize = othS;
      _totalSize = imgS + vidS + docS + audS + othS + _dbSize + _cacheSize;
      _isCalculating = false;
      _hasCalculatedOnce = true;
    });
  }

  static String _formatSize(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Storage Usage'),
      body: SafeArea(
        child: _isCalculating
            ? const CustomLoading()
            : RefreshIndicator(
                onRefresh: _calculateStorage,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  children: [
                    SizedBox(height: 24.h),
                    _buildOverviewCard(),
                    SizedBox(height: 20.h),
                    _buildSectionLabel('Manage Storage'),
                    SizedBox(height: 8.h),
                    SettingTile(
                      onTap: () async {
                        await Get.to(() => const GalleryPage());
                        _calculateStorage();
                      },
                      color: CustomColor.kPrimaryMedium,
                      icon: Icons.image_outlined,
                      title: 'Images',
                      subtitle:
                          '$_imagesCount files \u2022 ${_formatSize(_imagesSize)}',
                    ),
                    SizedBox(height: 4.h),
                    SettingTile(
                      onTap: () async {
                        await Get.to(() => const GalleryPage());
                        _calculateStorage();
                      },
                      color: CustomColor.kPrimaryDark,
                      icon: Icons.videocam_outlined,
                      title: 'Videos',
                      subtitle:
                          '$_videosCount files \u2022 ${_formatSize(_videosSize)}',
                    ),
                    SizedBox(height: 4.h),
                    SettingTile(
                      onTap: () => CustomSnackbar.show(
                          title: 'Coming Soon',
                          message:
                              'Document management will be available soon'),
                      color: CustomColor.kGoldAccent,
                      icon: Icons.description_outlined,
                      title: 'Documents',
                      subtitle:
                          '$_documentsCount files \u2022 ${_formatSize(_documentsSize)}',
                    ),
                    SizedBox(height: 4.h),
                    SettingTile(
                      onTap: () => CustomSnackbar.show(
                          title: 'Coming Soon',
                          message:
                              'Voice note management will be available soon'),
                      color: CustomColor.kOnlineGreen,
                      icon: Icons.mic_outlined,
                      title: 'Voice Notes',
                      subtitle:
                          '$_voiceCount files \u2022 ${_formatSize(_voiceSize)}',
                    ),
                    SizedBox(height: 20.h),
                    _buildSectionLabel('Auto-Download'),
                    SizedBox(height: 8.h),
                    _buildToggleTile(
                      icon: Icons.signal_cellular_alt_outlined,
                      title: 'When using mobile data',
                      value: _autoDownloadMobile,
                      onChanged: (v) {
                        setState(() => _autoDownloadMobile = v);
                        _getStorage.write('auto_download_mobile', v);
                        _getStorage.save();
                      },
                    ),
                    SizedBox(height: 4.h),
                    _buildToggleTile(
                      icon: Icons.wifi_outlined,
                      title: 'When connected to Wi-Fi',
                      value: _autoDownloadWifi,
                      onChanged: (v) {
                        setState(() => _autoDownloadWifi = v);
                        _getStorage.write('auto_download_wifi', v);
                        _getStorage.save();
                      },
                    ),
                    SizedBox(height: 4.h),
                    _buildToggleTile(
                      icon: Icons.airplanemode_active_outlined,
                      title: 'When roaming',
                      value: _autoDownloadRoaming,
                      onChanged: (v) {
                        setState(() => _autoDownloadRoaming = v);
                        _getStorage.write('auto_download_roaming', v);
                        _getStorage.save();
                      },
                    ),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final items = <_BreakdownItem>[
      _BreakdownItem('Images', _imagesSize, CustomColor.kPrimaryMedium,
          Icons.image_outlined),
      _BreakdownItem('Videos', _videosSize, CustomColor.kPrimaryDark,
          Icons.videocam_outlined),
      _BreakdownItem('Documents', _documentsSize, CustomColor.kGoldAccent,
          Icons.description_outlined),
      _BreakdownItem('Voice Notes', _voiceSize, CustomColor.kOnlineGreen,
          Icons.mic_outlined),
      _BreakdownItem('Cache', _cacheSize, CustomColor.kWarning,
          Icons.cleaning_services_outlined),
      _BreakdownItem('Database', _dbSize, CustomColor.kPrimaryLight,
          Icons.storage_outlined),
      _BreakdownItem('Other', _otherSize, CustomColor.kTextTertiary,
          Icons.folder_outlined),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xxl.r),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage Overview',
                style: AppTextStyles.headingSm
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
              Text(
                _formatSize(_totalSize),
                style: AppTextStyles.headingMd
                    .copyWith(color: CustomColor.kPrimaryColor),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Total storage used',
            style:
                AppTextStyles.bodySm.copyWith(color: CustomColor.kTextTertiary),
          ),
          SizedBox(height: 16.h),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.lg.r),
                      ),
                      child: Icon(item.icon, size: 16.r, color: item.color),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTextStyles.subtitle
                            .copyWith(color: CustomColor.kTextPrimary),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _formatSize(item.size),
                      style: AppTextStyles.label
                          .copyWith(color: CustomColor.kTextSecondary),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w),
      child: Text(
        text,
        style: AppTextStyles.subtitle
            .copyWith(color: CustomColor.kTextTertiary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl.w, vertical: AppSpacing.md.h),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl.r),
              color: CustomColor.kUltraLightPrimary,
            ),
            child: Icon(icon,
                color: CustomColor.kPrimaryColor, size: AppSpacing.lg.r),
          ),
          SizedBox(width: AppSpacing.xl.w),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMd
                  .copyWith(color: CustomColor.kTextPrimary),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: CustomColor.kPrimaryColor,
          ),
        ],
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final double size;
  final Color color;
  final IconData icon;
  const _BreakdownItem(this.label, this.size, this.color, this.icon);
}
