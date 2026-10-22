import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';

class Utils {
  static void showGetSnackBar(String message, {int? duration}) {
    if (message.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Get.overlayContext;
      if (ctx != null && ctx.mounted && Overlay.maybeOf(ctx) != null) {
        try {
          CustomSnackbar.show(message: message);
          return;
        } catch (_) {}
      }
      try {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: duration ?? 2,
          backgroundColor: CustomColor.kPrimaryFill,
          textColor: CustomColor.kTextOnDark,
          fontSize: 16.sp,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (_) {}
    });
  }

  static void showToast(String message, Toast length, {Color? color}) {
    if (message.isEmpty) return;

    try {
      Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
          backgroundColor: color ?? CustomColor.kPrimaryColor,
          textColor: CustomColor.kTextOnDark,
          fontSize: 16.sp,
          gravity: ToastGravity.BOTTOM);
    } catch (_) {}
  }
}
