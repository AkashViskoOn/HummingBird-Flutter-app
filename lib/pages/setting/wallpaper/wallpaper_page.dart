import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:humming_bird/controllers/chat_customization_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class WallpaperPage extends StatefulWidget {
  const WallpaperPage({super.key});

  @override
  State<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends State<WallpaperPage> {
  late ChatCustomizationController controller;
  final _picker = ImagePicker();

  static const _presetColors = [
    CustomColor.kSlate200,
    CustomColor.kInk700,
    CustomColor.kSuccess,
    CustomColor.kBrandIndigo,
    CustomColor.kBrandPink,
    CustomColor.kWarning,
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.find();
  }

  void _selectColor(Color color) {
    final hex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    controller.setWallpaperColor(hex);
    setState(() {});
  }

  void _selectGradient(String key) {
    controller.setWallpaperGradient(key);
    setState(() {});
  }

  Future<void> _pickImage() async {
    try {
      // Request gallery permission — READ_MEDIA_IMAGES on Android 13+, READ_EXTERNAL_STORAGE below.
      final status = await Permission.photos.request();
      if (!status.isGranted && !status.isLimited) {
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Gallery permission is required to set a wallpaper')),
          );
        }
        return;
      }
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        await controller.persistWallpaperImage(file.path);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _reset() {
    controller.resetWallpaper();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Chat Wallpaper'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GetBuilder<ChatCustomizationController>(
                builder: (_) {
                  return ListView(
                    padding: EdgeInsets.all(AppSpacing.page.w),
                    children: [
                      _buildPreview(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildTypeSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      if (controller.wallpaperCustomPath.value.isNotEmpty)
                        _buildImageTuning()
                      else ...[
                        _buildColorGrid(),
                        SizedBox(height: AppSpacing.xsection.h),
                        _buildGradientGrid(),
                        if (controller.wallpaperColorHex.value.isNotEmpty ||
                            controller.wallpaperGradientKey.value.isNotEmpty)
                          _buildImageTuning(),
                      ],
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildGalleryTile(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildGlobalToggle(),
                      SizedBox(height: AppSpacing.xl.h),
                      _buildResetButton(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMd.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      height: 160.h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          controller.buildWallpaperLayer(context: context),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg.w, vertical: AppSpacing.sm.h),
              decoration: BoxDecoration(
                color: CustomColor.kGlassColor,
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                border: Border.all(
                  color: CustomColor.kTextOnDark.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Preview',
                style: AppTextStyles.label.copyWith(
                  color: CustomColor.kTextOnDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTiles() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeTile(
            label: 'Solid Color',
            icon: Icons.palette_outlined,
            selected: controller.wallpaperColorHex.value.isNotEmpty,
            onTap: () {},
          ),
        ),
        SizedBox(width: AppSpacing.md.w),
        Expanded(
          child: _buildTypeTile(
            label: 'Gradient',
            icon: Icons.gradient,
            selected: controller.wallpaperGradientKey.value.isNotEmpty,
            onTap: () {},
          ),
        ),
        SizedBox(width: AppSpacing.md.w),
        Expanded(
          child: _buildTypeTile(
            label: 'Image',
            icon: Icons.image_outlined,
            selected: controller.wallpaperCustomPath.value.isNotEmpty,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTile({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? CustomColor.kUltraLightPrimary : CustomColor.kWhite,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
            color:
                selected ? CustomColor.kPrimaryColor : CustomColor.kLightBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20.r,
                color: selected
                    ? CustomColor.kPrimaryColor
                    : CustomColor.kTextTertiary),
            SizedBox(height: 4.h),
            Text(label, style: AppTextStyles.labelSm),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Wallpaper Type'),
        SizedBox(height: AppSpacing.md.h),
        _buildHeaderTiles(),
      ],
    );
  }

  Widget _buildColorGrid() {
    final selectedHex = controller.wallpaperColorHex.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Default Wallpapers'),
        SizedBox(height: AppSpacing.md.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _presetColors.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final color = _presetColors[index];
            final hex =
                '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
            final selected = selectedHex == hex &&
                controller.wallpaperGradientKey.value.isEmpty;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectColor(color),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  border: selected
                      ? Border.all(color: CustomColor.kPrimaryColor, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: selected
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.all(5.r),
                          decoration: const BoxDecoration(
                            color: CustomColor.kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: CustomColor.kWhite,
                            size: 16.r,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGradientGrid() {
    final gradients = ChatCustomizationController.wallpaperGradientKeys;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gradient Wallpapers',
          style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: AppSpacing.md.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gradients.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final key = gradients[index];
            final colors = ChatCustomizationController.gradientColors(key);
            final selected = controller.wallpaperGradientKey.value == key;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectGradient(key),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: selected
                      ? Border.all(color: CustomColor.kPrimaryColor, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: selected
                    ? Center(
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: CustomColor.kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: CustomColor.kWhite,
                            size: 16.r,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGalleryTile() {
    final hasCustom = controller.wallpaperCustomPath.value.isNotEmpty;
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl.w,
          vertical: AppSpacing.lg.h,
        ),
        decoration: BoxDecoration(
          color: CustomColor.kWhite,
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                gradient: CustomColor.primaryGradient,
              ),
              child: Icon(
                Icons.image_outlined,
                color: CustomColor.kWhite,
                size: 22.r,
              ),
            ),
            SizedBox(width: AppSpacing.xl.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose from Gallery',
                    style: AppTextStyles.titleMd.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasCustom) ...[
                    SizedBox(height: AppSpacing.xxs.h),
                    Text(
                      'Custom wallpaper selected',
                      style: AppTextStyles.helper.copyWith(
                        color: CustomColor.kPrimaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: CustomColor.kTextTertiary,
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalToggle() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply to all chats',
                  style: AppTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs.h),
                Text(
                  'When off, wallpaper applies only to this chat',
                  style: AppTextStyles.helper,
                ),
              ],
            ),
          ),
          Switch(
            value: controller.wallpaperGlobal.value,
            activeTrackColor: CustomColor.kPrimaryColor,
            onChanged: (val) {
              controller.setWallpaperGlobal(val);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMd),
            Text(
              display,
              style: AppTextStyles.label.copyWith(
                color: CustomColor.kPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: CustomColor.kPrimaryColor,
          inactiveColor: CustomColor.kPrimaryLight,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildImageTuning() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl.w),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSliderRow(
            label: 'Blur',
            value: controller.wallpaperBlur.value,
            min: 0,
            max: 20,
            divisions: 20,
            display: '${controller.wallpaperBlur.value.round()}',
            onChanged: (v) {
              controller.setWallpaperBlur(v);
              setState(() {});
            },
          ),
          _buildSliderRow(
            label: 'Opacity',
            value: controller.wallpaperOpacity.value,
            min: 0.25,
            max: 1,
            divisions: 15,
            display: '${(controller.wallpaperOpacity.value * 100).round()}%',
            onChanged: (v) {
              controller.setWallpaperOpacity(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: _reset,
      icon: Icon(Icons.refresh_rounded, size: 18.r),
      label: const Text('Reset Wallpaper'),
      style: OutlinedButton.styleFrom(
        foregroundColor: CustomColor.kDangerRed,
        side: BorderSide(color: CustomColor.kDangerRed.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.h),
      ),
    );
  }
}
