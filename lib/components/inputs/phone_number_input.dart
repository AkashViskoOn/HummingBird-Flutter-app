import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class PhoneNumberInput extends StatefulWidget {
  final TextEditingController controller;
  const PhoneNumberInput({super.key, required this.controller});

  @override
  State<PhoneNumberInput> createState() => _PhoneNumberInputState();
}

class _PhoneNumberInputState extends State<PhoneNumberInput> {
  final FocusNode _focusNode = FocusNode();
  bool isTyping = false;

  @override
  void initState() {
    // TODO: implement initState
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          isTyping = true;
        });
      } else {
        setState(() {
          isTyping = false;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
      padding: EdgeInsets.only(
          top: AppSpacing.sm.h,
          left: 15.w,
          bottom: AppSpacing.sm.h,
          right: 0.w),
      decoration: BoxDecoration(
          color: CustomColor.kTextOnDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.05),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ]),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            hintText: "+91 | *** *** ** **",
            hintStyle: AppTextStyles.headingMd.copyWith(
                fontWeight: FontWeight.w400, color: CustomColor.kTextTertiary),
            border: OutlineInputBorder(borderSide: BorderSide.none)),
      ),
    );
  }
}
