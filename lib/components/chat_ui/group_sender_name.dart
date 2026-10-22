import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_spacing.dart';

class SenderNameContainer extends StatelessWidget {
  final String senderId;
  final double? avatarSize;
  final Color? nameColor;
  const SenderNameContainer({
    super.key,
    required this.senderId,
    this.avatarSize,
    this.nameColor,
  });

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.find();
    final size = avatarSize ?? 26.r;
    final profilePic = contactController.getUserProfilePic(senderId);
    final name = contactController.getUserNameById(senderId).split(' ')[0];
    return Padding(
      padding: EdgeInsets.only(
          top: AppSpacing.xs.h, left: AppSpacing.xl.w, bottom: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: profilePic.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: profilePic,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _avatarFallback(size, name),
                  )
                : _avatarFallback(size, name),
          ),
          SizedBox(width: AppSpacing.xs.w),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: (avatarSize != null ? size * 0.38 : 11.sp),
                fontWeight: FontWeight.w600,
                color: nameColor ?? CustomColor.kPrimaryColor,
                letterSpacing: null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(double size, String name) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: CustomColor.kUltraLightPrimary,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: CustomColor.kPrimaryColor,
        ),
      ),
    );
  }
}
