import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/res/colors.dart';

class BlurWidget extends StatelessWidget {
  const BlurWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
        color: CustomColor.kTextOnDark.withValues(alpha: 0.05),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            alignment: Alignment.center,
            color: CustomColor.kTextOnDark.withValues(alpha: 0.05),
          ),
        ),
      ),
    );
  }
}
