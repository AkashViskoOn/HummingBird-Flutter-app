import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class PickDateField extends StatelessWidget {
  final bool fromBottomSheet;
  const PickDateField({super.key, this.fromBottomSheet = false});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
    return TextFormField(
      controller: chatController.dateController,
      style: AppTextStyles.bodyMd.copyWith(
          color: isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary),
      decoration: InputDecoration(
        prefixIcon: fromBottomSheet
            ? Container(
                padding: EdgeInsets.all(7.r),
                child: Icon(
                  Icons.calendar_month,
                  size: 22.r,
                  color: CustomColor.kPrimaryColor,
                ),
              )
            : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
          borderSide: BorderSide(color: CustomColor.kPrimaryColor, width: 1.5),
        ),
        icon: fromBottomSheet
            ? null
            : Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CustomColor.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.calendar_month,
                  size: 22.r,
                  color: CustomColor.kTextOnDark,
                ),
              ),
        hintText: 'Pick Date',
        hintStyle: AppTextStyles.bodyMd.copyWith(
            color: isDark
                ? CustomColor.kTextOnDarkMuted
                : CustomColor.kTextTertiary),
      ),
      onTap: () async {
        DateTime? pickedDate = DateTime(2000);
        FocusScope.of(context).requestFocus(FocusNode());
        pickedDate = await showDatePicker(
            barrierDismissible: false,
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100));

        if (pickedDate != null) {
          String formattedDate =
              DateFormat('EEE, d MMM yyyy').format(pickedDate);
          chatController.dateController.text = formattedDate.toString();
          chatController.pickedDate = pickedDate;
        }
      },
    );
  }
}
