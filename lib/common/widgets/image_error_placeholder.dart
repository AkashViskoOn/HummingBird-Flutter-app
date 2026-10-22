import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';

/// Fallback widget shown whenever an [Image] widget fails to decode its
/// bytes. Prevents "Invalid image data" exceptions from reaching the
/// framework and crashing (debug) runs.
class ImageErrorPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? iconColor;

  const ImageErrorPlaceholder({
    super.key,
    this.width,
    this.height,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: CustomColor.kUltraLightBg,
      child: Icon(
        Icons.broken_image_outlined,
        color: iconColor ?? CustomColor.kTextTertiary,
        size: 28.r,
      ),
    );
  }
}
