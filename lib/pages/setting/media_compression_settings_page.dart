import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class MediaCompressionSettingsPage extends StatefulWidget {
  const MediaCompressionSettingsPage({super.key});

  @override
  State<MediaCompressionSettingsPage> createState() =>
      _MediaCompressionSettingsPageState();
}

class _MediaCompressionSettingsPageState
    extends State<MediaCompressionSettingsPage> {
  final storage = GetStorage();
  late bool autoCompress;
  late String quality;

  final _qualityOptions = [
    {
      'value': 'none',
      'label': 'None',
      'desc': 'Original quality, largest file size'
    },
    {
      'value': 'low',
      'label': 'Low',
      'desc': 'Maximum compression, smallest file size'
    },
    {'value': 'medium', 'label': 'Medium', 'desc': 'Balanced quality and size'},
    {
      'value': 'high',
      'label': 'High',
      'desc': 'Near-original quality, slight compression'
    },
  ];

  final _savingsInfo = {
    'none': '0%',
    'low': '~70%',
    'medium': '~50%',
    'high': '~20%',
  };

  @override
  void initState() {
    super.initState();
    autoCompress = storage.read('autoCompressMedia') ?? false;
    quality = storage.read('mediaCompressionQuality') ?? 'medium';
  }

  void _save() {
    storage.write('autoCompressMedia', autoCompress);
    storage.write('mediaCompressionQuality', quality);
    Get.back();
    CustomSnackbar.success(
        title: 'Saved', message: 'Compression settings updated');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Media Compression', actions: [
        TextButton(
          onPressed: _save,
          child: Text('Save',
              style: GoogleFonts.poppins(
                  color: CustomColor.primaryTextFor(
                      Theme.of(context).brightness == Brightness.dark),
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: CustomColor.kTextOnDark,
              borderRadius: BorderRadius.circular(AppRadius.xxl.r),
              boxShadow: [
                BoxShadow(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.compress,
                        color: CustomColor.kPrimaryColor, size: 20.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text('Auto-compress Media',
                          style: AppTextStyles.titleMd
                              .copyWith(color: CustomColor.kTextPrimary)),
                    ),
                    SizedBox(width: 8.w),
                    Switch(
                      value: autoCompress,
                      onChanged: (v) => setState(() => autoCompress = v),
                      activeThumbColor: CustomColor.kPrimaryColor,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  'Automatically compress images and videos before sending',
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kTextSecondary),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text('Compression Quality',
              style: AppTextStyles.titleSm
                  .copyWith(color: CustomColor.kTextPrimary)),
          SizedBox(height: 8.h),
          ..._qualityOptions.map((opt) {
            final val = opt['value'] as String;
            final isSelected = quality == val;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: GestureDetector(
                onTap: () => setState(() => quality = val),
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CustomColor.kPrimaryLight
                        : CustomColor.kTextOnDark,
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                    border: Border.all(
                      color: isSelected
                          ? CustomColor.kPrimaryColor
                          : CustomColor.kLightBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: val,
                        groupValue: quality,
                        onChanged: (v) =>
                            setState(() => quality = v ?? 'medium'),
                        activeColor: CustomColor.kPrimaryColor,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(opt['label'] as String,
                                style: AppTextStyles.titleSm
                                    .copyWith(color: CustomColor.kTextPrimary)),
                            SizedBox(height: 2.h),
                            Text(opt['desc'] as String,
                                style: AppTextStyles.caption.copyWith(
                                    color: CustomColor.kTextSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CustomColor.kPrimaryColor
                              : CustomColor.kUltraLightBg,
                          borderRadius: BorderRadius.circular(AppRadius.md.r),
                        ),
                        child: Text(
                          _savingsInfo[val] ?? '',
                          style: AppTextStyles.caption.copyWith(
                              color: isSelected
                                  ? CustomColor.kTextOnDark
                                  : CustomColor.kTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: CustomColor.kUltraLightPrimary,
              borderRadius: BorderRadius.circular(AppRadius.xl.r),
              border: Border.all(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: CustomColor.kPrimaryColor, size: 20.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Estimated savings are approximate and vary by content type.',
                    style: AppTextStyles.bodySm
                        .copyWith(color: CustomColor.kTextSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
