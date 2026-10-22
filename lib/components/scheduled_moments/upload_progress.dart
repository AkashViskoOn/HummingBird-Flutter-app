import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class UploadProgressDialog extends StatelessWidget {
  final double progress;
  final String statusText;

  const UploadProgressDialog({
    super.key,
    required this.progress,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? CustomColor.kDarkSurface
            : CustomColor.kTextOnDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl.r)),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.r,
                height: 56.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                ),
                child: progress >= 1.0
                    ? Icon(Icons.check_rounded,
                        color: CustomColor.kOnlineGreen, size: 28.r)
                    : SizedBox(
                        width: 24.r,
                        height: 24.r,
                        child: CircularProgressIndicator(
                          value: progress > 0 ? progress : null,
                          strokeWidth: 3,
                          color: CustomColor.kPrimaryColor,
                        ),
                      ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm.r),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 4.h,
                    backgroundColor: CustomColor.kLightBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        CustomColor.kPrimaryColor),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                statusText,
                style: AppTextStyles.subtitle.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary),
                textAlign: TextAlign.center,
              ),
              if (progress >= 1.0) ...[
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Done',
                        style: GoogleFonts.poppins(
                            color: CustomColor.primaryTextFor(Get.isDarkMode))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void showUploadProgress({
  required double progress,
  required String statusText,
}) {
  if (Get.isDialogOpen ?? false) {
    Get.back();
  }
  Get.dialog(
    UploadProgressDialog(progress: progress, statusText: statusText),
    barrierDismissible: false,
  );
}
