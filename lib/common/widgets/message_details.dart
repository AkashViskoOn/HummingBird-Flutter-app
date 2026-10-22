import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class MessageDetails extends StatelessWidget {
  final String sentTime;
  final bool seen;
  const MessageDetails({super.key, required this.sentTime, required this.seen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sentTime,
            style: AppTextStyles.labelSm
                .copyWith(color: CustomColor.kTextTertiary),
          ),
          SizedBox(width: 4.w),
          Icon(
            seen ? Icons.done_all : Icons.check,
            size: 12.r,
            color: seen ? CustomColor.kPrimaryColor : CustomColor.kTextTertiary,
          ),
        ],
      ),
    );
  }
}
