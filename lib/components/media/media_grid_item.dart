import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class MediaGridItem extends StatelessWidget {
  final String mediaUrl;
  final String mediaType;
  final String? duration;
  final String? dateLabel;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MediaGridItem({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.duration,
    this.dateLabel,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md.r),
          border: isSelected
              ? Border.all(color: CustomColor.kPrimaryColor, width: 3)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: mediaUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: CustomColor.kUltraLightBg,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: CustomColor.kPrimaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: CustomColor.kUltraLightBg,
                  child: Icon(Icons.broken_image_outlined,
                      color: CustomColor.kTextTertiary),
                ),
              ),
              if (mediaType == '4')
                Positioned(
                  right: 4.r,
                  top: 4.r,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.xs.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: CustomColor.kTextOnDark, size: 12.sp),
                        if (duration != null)
                          Text(
                            duration!,
                            style: AppTextStyles.labelSm
                                .copyWith(color: CustomColor.kTextOnDark),
                          ),
                      ],
                    ),
                  ),
                ),
              if (dateLabel != null)
                Positioned(
                  left: 4.r,
                  bottom: 4.r,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.xs.r),
                    ),
                    child: Text(
                      dateLabel!,
                      style: AppTextStyles.labelSm
                          .copyWith(color: CustomColor.kTextOnDark),
                    ),
                  ),
                ),
              if (isSelected)
                Positioned(
                  right: 4.r,
                  bottom: 4.r,
                  child: Container(
                    width: 20.r,
                    height: 20.r,
                    decoration: const BoxDecoration(
                      color: CustomColor.kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check,
                        color: CustomColor.kTextOnDark, size: 14.r),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
