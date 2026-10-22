import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class ProfileQrCodeSheet {
  ProfileQrCodeSheet._();

  static void show(BuildContext context, {required String name}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProfileQrCodeSheet(name: name),
    );
  }
}

class _ProfileQrCodeSheet extends StatelessWidget {
  final String name;
  const _ProfileQrCodeSheet({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.55,
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.rounded.r),
          topRight: Radius.circular(AppRadius.rounded.r),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: AppSpacing.section.h),
          Container(
            width: 40.r,
            height: 4.r,
            decoration: BoxDecoration(
              color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.xxs.r),
            ),
          ),
          SizedBox(height: AppSpacing.xxl.h),
          Text(
            'Your QR Code',
            style:
                AppTextStyles.headingMd.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: AppSpacing.xxs.h),
          Text(
            name.isEmpty ? 'Humming Bird User' : name,
            style: AppTextStyles.subtitle
                .copyWith(color: CustomColor.kTextSecondary),
          ),
          SizedBox(height: AppSpacing.xxl.h),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxxl.w),
              child: Center(
                child: CustomPaint(
                  size: Size(220.r, 220.r),
                  painter: _ProfileQrCodePainter(),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xxl.h),
        ],
      ),
    );
  }
}

class _ProfileQrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CustomColor.kPrimaryColor
      ..style = PaintingStyle.fill;
    final bgPaint = Paint()
      ..color = CustomColor.kPrimaryLight
      ..style = PaintingStyle.fill;
    final cell = size.width / 11;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(12.r),
        ),
        bgPaint);
    final positions = [
      [0, 0],
      [2, 0],
      [4, 0],
      [6, 0],
      [8, 0],
      [10, 0],
      [0, 2],
      [2, 2],
      [10, 2],
      [0, 4],
      [4, 4],
      [6, 4],
      [10, 4],
      [0, 6],
      [4, 6],
      [10, 6],
      [0, 8],
      [2, 8],
      [4, 8],
      [6, 8],
      [8, 8],
      [10, 8],
      [0, 10],
      [10, 10],
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [0, 1],
      [3, 1],
      [0, 2],
      [3, 2],
      [0, 3],
      [1, 3],
      [2, 3],
      [3, 3],
      [7, 0],
      [8, 0],
      [9, 0],
      [10, 0],
      [7, 1],
      [10, 1],
      [7, 2],
      [10, 2],
      [7, 3],
      [8, 3],
      [9, 3],
      [10, 3],
      [0, 7],
      [3, 7],
      [0, 8],
      [3, 8],
      [0, 9],
      [3, 9],
      [0, 10],
      [1, 10],
      [2, 10],
      [3, 10],
    ];
    for (final pos in positions) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                pos[0] * cell + 2, pos[1] * cell + 2, cell - 4, cell - 4),
            Radius.circular(3.r),
          ),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
