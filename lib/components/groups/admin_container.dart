import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AdminContainer extends StatelessWidget {
  final double fontSize;
  const AdminContainer({super.key, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CustomColor.kSuccess, CustomColor.kSuccess],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kSuccess.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded,
              size: (fontSize + 1).r, color: CustomColor.kTextOnDark),
          SizedBox(width: 2.w),
          Text(
            'Admin',
            style: GoogleFonts.poppins(
              fontSize: fontSize.sp,
              fontWeight: FontWeight.w700,
              color: CustomColor.kTextOnDark,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
