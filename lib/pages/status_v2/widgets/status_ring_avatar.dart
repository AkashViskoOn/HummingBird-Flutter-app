import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';

/// WhatsApp-style status ring avatar.
/// Brand gradient ring; grey ring when [viewed] is true.
class StatusRingAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double ringWidth;
  final bool viewed;
  final bool isMyStatus;
  final bool alwaysColorRing;
  final Widget? fallbackChild;

  const StatusRingAvatar({
    super.key,
    this.imageUrl,
    this.size = 56,
    this.ringWidth = 3,
    this.viewed = false,
    this.isMyStatus = false,
    this.alwaysColorRing = false,
    this.fallbackChild,
  });

  @override
  Widget build(BuildContext context) {
    final showGreyRing = viewed && !isMyStatus && !alwaysColorRing;
    final avatar = imageUrl == null || imageUrl!.isEmpty
        ? (fallbackChild ??
            Image.asset(
              AppAssets.defaultProfilePic,
              width: size.r,
              height: size.r,
              fit: BoxFit.cover,
            ))
        : CachedNetworkImage(
            imageUrl: '${Endpoints.mediaBaseUrl}$imageUrl',
            width: size.r,
            height: size.r,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: CustomColor.kUltraLightBg,
              alignment: Alignment.center,
              child: Icon(
                Icons.person_rounded,
                size: size.r * 0.5,
                color: CustomColor.kTextTertiary,
              ),
            ),
            errorWidget: (_, __, ___) => Image.asset(
              AppAssets.defaultProfilePic,
              width: size.r,
              height: size.r,
              fit: BoxFit.cover,
            ),
          );

    return Container(
      width: (size + ringWidth * 2 + 2).r,
      height: (size + ringWidth * 2 + 2).r,
      padding: EdgeInsets.all(ringWidth.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: showGreyRing ? null : CustomColor.primaryGradient,
        color: showGreyRing ? CustomColor.kLightBorder : null,
      ),
      child: Container(
        padding: EdgeInsets.all(1.5.r),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: CustomColor.kWhite,
        ),
        child: ClipOval(child: avatar),
      ),
    );
  }
}
