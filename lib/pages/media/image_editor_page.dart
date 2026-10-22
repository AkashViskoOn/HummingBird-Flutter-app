import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class ImageEditorPage extends StatefulWidget {
  final Uint8List imageBytes;
  const ImageEditorPage({super.key, required this.imageBytes});

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  int _rotation = 0;
  double _brightness = 0.0;
  double _contrast = 1.0;
  final double _saturation = 1.0;
  final double _freeRotate = 0.0;
  String _filter = 'none';
  bool _isDrawing = false;
  Color _drawColor = Colors.red;
  double _brushSize = 3.0;
  String? _textOverlay;
  Color _textColor = CustomColor.kTextOnDark;
  double _textSize = 24.0;
  Offset _textPosition = const Offset(100, 100);
  ui.Image? _loadedImage;

  final List<Color> _colorPalette = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    CustomColor.kTextOnDark,
    Colors.black,
  ];

  final List<String> _filters = ['none', 'grayscale', 'sepia'];

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      _loadedImage = frame.image;
      if (mounted) setState(() {});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Image load error: $e');
      }
    }
  }

  List<double> _getColorFilterMatrix() {
    final b = _brightness;
    final c = _contrast;
    final s = _saturation;

    switch (_filter) {
      case 'grayscale':
        return [
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      case 'sepia':
        return [
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ];
      default:
        return [
          c * s,
          0,
          0,
          0,
          b,
          0,
          c * s,
          0,
          0,
          b,
          0,
          0,
          c * s,
          0,
          b,
          0,
          0,
          0,
          1,
          0,
        ];
    }
  }

  void _apply() {
    Get.back(result: widget.imageBytes);
  }

  Widget _buildToolbar() {
    return Container(
      height: 56.h,
      color: CustomColor.kDarkSurface2,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        children: [
          _toolButton(Icons.crop_rotate, 'Crop', () {}),
          _toolButton(Icons.rotate_left, 'Rotate', () {
            setState(() => _rotation = (_rotation - 90) % 360);
          }),
          _toolButton(Icons.rotate_right, 'R-90', () {
            setState(() => _rotation = (_rotation + 90) % 360);
          }),
          _toolButton(Icons.brush_rounded, 'Draw', () {
            setState(() => _isDrawing = !_isDrawing);
          }),
          _toolButton(Icons.text_fields, 'Text', () => _showTextDialog()),
          _toolButton(Icons.filter, 'Filter', () => _cycleFilter()),
          _toolButton(Icons.brightness_6, 'Bright', () {
            setState(() => _brightness = _brightness >= 0.5 ? 0.0 : 0.3);
          }),
          _toolButton(Icons.contrast, 'Contrast', () {
            setState(() => _contrast = _contrast >= 1.5 ? 1.0 : 1.5);
          }),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: CustomColor.kOverlay6,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: CustomColor.kTextOnDark, size: 18.r),
              SizedBox(height: 2.h),
              Text(label,
                  style: AppTextStyles.labelSm
                      .copyWith(color: CustomColor.kOverlay70)),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleFilter() {
    final idx = _filters.indexOf(_filter);
    setState(() => _filter = _filters[(idx + 1) % _filters.length]);
  }

  void _showTextDialog() {
    final controller = TextEditingController(text: _textOverlay ?? '');
    Get.dialog(
      AlertDialog(
        backgroundColor: CustomColor.kDarkSurface,
        title: Text('Add Text',
            style: GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: GoogleFonts.poppins(color: CustomColor.kTextOnDark),
              decoration: InputDecoration(
                hintText: 'Enter text...',
                hintStyle: GoogleFonts.poppins(
                    color: CustomColor.kTextOnDarkSecondary),
                filled: true,
                fillColor: CustomColor.kDarkSurface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              children: _colorPalette.map((c) {
                return GestureDetector(
                  onTap: () => _textColor = c,
                  child: Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _textColor == c
                            ? CustomColor.kTextOnDark
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text('Size',
                    style: GoogleFonts.poppins(color: CustomColor.kOverlay70)),
                Expanded(
                  child: Slider(
                    value: _textSize,
                    min: 12,
                    max: 72,
                    onChanged: (v) => _textSize = v,
                    activeColor: CustomColor.kPrimaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _textOverlay = controller.text;
              });
              Get.back();
            },
            child: Text('Add',
                style: GoogleFonts.poppins(
                    color: CustomColor.primaryTextFor(Get.isDarkMode))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.kDarkBackground,
      appBar: CommonAppBar(
        title: 'Edit Image',
        backgroundColor: CustomColor.kDarkSurface,
        showBackButton: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, color: CustomColor.kTextOnDark),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: _apply,
            child: Text('Confirm',
                style: AppTextStyles.headingSm
                    .copyWith(color: CustomColor.kPrimaryColor)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isDrawing ? _buildDrawingCanvas() : _buildImagePreview(),
          ),
          if (_isDrawing) _buildDrawingTools(),
          _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(_getColorFilterMatrix()),
        child: Transform.rotate(
          angle: (_rotation + _freeRotate) * (3.14159 / 180),
          child: _loadedImage != null
              ? RawImage(
                  image: _loadedImage,
                  fit: BoxFit.contain,
                  width: Get.width,
                )
              : const Center(
                  child: CircularProgressIndicator(
                      color: CustomColor.kPrimaryColor)),
        ),
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return GestureDetector(
      onPanUpdate: (details) {},
      child: Stack(
        children: [
          _buildImagePreview(),
          if (_textOverlay != null && _textOverlay!.isNotEmpty)
            Positioned(
              left: _textPosition.dx,
              top: _textPosition.dy,
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _textPosition += d.delta),
                child: Text(
                  _textOverlay!,
                  style: GoogleFonts.poppins(
                    color: _textColor,
                    fontSize: _textSize.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawingTools() {
    return Container(
      height: 60.h,
      color: CustomColor.kDarkSurface,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Wrap(
            spacing: 8.w,
            children: _colorPalette.map((c) {
              return GestureDetector(
                onTap: () => setState(() => _drawColor = c),
                child: Container(
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _drawColor == c
                          ? CustomColor.kTextOnDark
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Slider(
              value: _brushSize,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _brushSize = v),
              activeColor: CustomColor.kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
