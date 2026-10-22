import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/common/widgets/image_error_placeholder.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class StatusPhotoEditor extends StatefulWidget {
  final File imageFile;
  final String? initialCaption;

  const StatusPhotoEditor({
    super.key,
    required this.imageFile,
    this.initialCaption,
  });

  @override
  State<StatusPhotoEditor> createState() => _StatusPhotoEditorState();
}

class _StatusPhotoEditorState extends State<StatusPhotoEditor> {
  final TextEditingController _captionCtrl = TextEditingController();
  final StatusController _statusCtrl = Get.find();
  bool _isUploading = false;

  // Filter simulation
  final List<ColorFilter> _filters = [
    const ColorFilter.matrix(<double>[
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ]), // normal
    const ColorFilter.matrix(<double>[
      0.33,
      0.33,
      0.33,
      0,
      0,
      0.33,
      0.33,
      0.33,
      0,
      0,
      0.33,
      0.33,
      0.33,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ]), // grayscale
    const ColorFilter.matrix(<double>[
      0.39,
      0.76,
      0.19,
      0,
      0,
      0.39,
      0.76,
      0.19,
      0,
      0,
      0.39,
      0.76,
      0.19,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ]), // sepia
    const ColorFilter.mode(Colors.blue, BlendMode.modulate),
    const ColorFilter.mode(Colors.orange, BlendMode.modulate),
    const ColorFilter.mode(Colors.purple, BlendMode.modulate),
  ];
  int _selectedFilter = 0;
  double _brightness = 0;
  double _contrast = 1;

  Future<void> _share() async {
    setState(() => _isUploading = true);
    try {
      final result = await _statusCtrl.createUpdate(
        _captionCtrl.text,
        file: widget.imageFile,
        mediaType: 'image',
      );
      if (result != null) {
        Get.back();
        Get.back();
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CommonAppBar(
        title: '',
        backgroundColor: Colors.black,
        showBackButton: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, color: CustomColor.kTextOnDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isUploading
              ? Padding(
                  padding: EdgeInsets.all(16.r),
                  child: const CircularProgressIndicator(
                      color: CustomColor.kTextOnDark))
              : TextButton(
                  onPressed: _share,
                  child: Text('Share',
                      style: GoogleFonts.poppins(
                          color: CustomColor.kTextOnDark,
                          fontWeight: FontWeight.w600)),
                ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix([
                  _contrast,
                  0,
                  0,
                  0,
                  128 * (1 - _contrast) + _brightness,
                  0,
                  _contrast,
                  0,
                  0,
                  128 * (1 - _contrast) + _brightness,
                  0,
                  0,
                  _contrast,
                  0,
                  128 * (1 - _contrast) + _brightness,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: ColorFiltered(
                  colorFilter: _filters[_selectedFilter],
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const ImageErrorPlaceholder(),
                  ),
                ),
              ),
            ),
          ),
          // Filter strip
          Container(
            height: 80.h,
            color: Colors.grey[900],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              itemCount: _filters.length,
              itemBuilder: (ctx, i) {
                final labels = [
                  'Normal',
                  'B&W',
                  'Sepia',
                  'Blue',
                  'Warm',
                  'Purple'
                ];
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: Container(
                    width: 60.w,
                    margin:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedFilter == i
                            ? CustomColor.kTextOnDark
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md.r),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ColorFiltered(
                            colorFilter: _filters[i],
                            child: Image.file(
                              widget.imageFile,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ImageErrorPlaceholder(),
                            ),
                          ),
                        ),
                        Text(labels[i],
                            style: AppTextStyles.labelSm
                                .copyWith(color: CustomColor.kTextOnDark)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Controls
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.grey[900],
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Brightness',
                        style: AppTextStyles.caption
                            .copyWith(color: CustomColor.kOverlay60)),
                    Expanded(
                      child: Slider(
                        value: _brightness,
                        min: -100,
                        max: 100,
                        onChanged: (v) => setState(() => _brightness = v),
                        activeColor: CustomColor.kTextOnDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('Contrast',
                        style: AppTextStyles.caption
                            .copyWith(color: CustomColor.kOverlay60)),
                    Expanded(
                      child: Slider(
                        value: _contrast,
                        min: 0.5,
                        max: 2.0,
                        onChanged: (v) => setState(() => _contrast = v),
                        activeColor: CustomColor.kTextOnDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _captionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: GoogleFonts.poppins(
                        color: CustomColor.kTextOnDarkSecondary),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: CustomColor.kOverlay12,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                  style: AppTextStyles.bodyMd
                      .copyWith(color: CustomColor.kTextOnDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
