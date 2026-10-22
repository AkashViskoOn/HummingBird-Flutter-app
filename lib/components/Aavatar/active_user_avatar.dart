import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class ActiveUserAvatar extends StatelessWidget {
  final String userName;
  final String filePath;
  final bool isActive;
  const ActiveUserAvatar(
      {super.key,
      required this.userName,
      required this.filePath,
      this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.r),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? CustomColor.kOnlineGreen
                        : Colors.transparent,
                    width: 2.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: filePath.isNotEmpty
                    ? CircleAvatar(
                        radius: 24.r,
                        backgroundImage: CachedNetworkImageProvider(
                            '${Endpoints.mediaBaseUrl}$filePath'),
                        onBackgroundImageError: (_, __) {},
                      )
                    : CircleAvatar(
                        radius: 24.r,
                        backgroundImage:
                            const AssetImage(AppAssets.defaultProfilePic),
                      ),
              ),
              SizedBox(height: 4.h),
              Text(
                userName,
                style: AppTextStyles.error
                    .copyWith(color: CustomColor.kTextPrimary),
              )
            ],
          ),
          if (isActive)
            Positioned(
              top: 0.h,
              right: 2.w,
              child: Container(
                width: 12.r,
                height: 12.r,
                decoration: BoxDecoration(
                  color: CustomColor.kOnlineGreen,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: CustomColor.kTextOnDark, width: 2.r),
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kOnlineGreen.withValues(alpha: 0.5),
                      blurRadius: 4.r,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
