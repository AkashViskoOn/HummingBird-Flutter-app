import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/profile_controller.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_radius.dart';

class PickDateOfBirthField extends StatelessWidget {
  final TextEditingController? controller;
  const PickDateOfBirthField({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.find();
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 16.sp),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 15.r, vertical: 15.r),
        prefixIcon: Icon(
          Icons.calendar_month,
          size: 25.r,
          color: CustomColor.kDarkPrimaryColor,
        ),
        hintText: 'Date of Birth (DD/MM/YYYY)',
        hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
          borderSide: BorderSide(color: CustomColor.kLightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
          borderSide: BorderSide(color: CustomColor.kLightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
          borderSide: BorderSide(color: CustomColor.kPrimaryColor, width: 1.5),
        ),
      ),
      onTap: () async {
        DateTime? pickedDate;
        FocusScope.of(context).requestFocus(FocusNode());
        pickedDate = await showDatePicker(
            barrierDismissible: false,
            context: context,
            lastDate: DateTime.now(),
            initialDate: DateTime.now(),
            firstDate: DateTime(1900));
        if (pickedDate != null) {
          String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
          profileController.dobController.text = formattedDate;
        }
      },
    );
  }
}
