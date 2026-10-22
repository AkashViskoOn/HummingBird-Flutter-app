import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class MeMessage extends StatelessWidget {
  final String message;
  const MeMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 80.w, right: 16.w),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: 0.70.sw),
          margin: EdgeInsets.symmetric(vertical: 3.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: CustomColor.sentBubbleGradient,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              bottomLeft: Radius.circular(18.r),
              topRight: Radius.circular(4.r),
              bottomRight: Radius.circular(18.r),
            ),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            style: AppTextStyles.bodyMd.copyWith(
              color: CustomColor.kTextOnDark,
            ),
          ),
        ),
      ),
    );
  }
}
