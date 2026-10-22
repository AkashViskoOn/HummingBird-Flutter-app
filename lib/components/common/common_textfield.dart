import 'package:flutter/material.dart';
import 'package:humming_bird/components/common/app_textfield.dart';

class CommonTextField extends StatelessWidget {
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final String hintText;
  final Color? bgColor;
  final bool needShadow;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;

  const CommonTextField({
    super.key,
    this.onChanged,
    this.controller,
    this.bgColor,
    this.needShadow = false,
    required this.hintText,
    this.suffixIcon,
    this.maxLines,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      onChanged: onChanged,
      controller: controller,
      hintText: hintText,
      bgColor: bgColor,
      needShadow: needShadow,
      suffixIcon: suffixIcon,
      maxLines: maxLines,
      maxLength: maxLength,
    );
  }
}
