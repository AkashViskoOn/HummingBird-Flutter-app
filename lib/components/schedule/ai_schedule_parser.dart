import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AiScheduleParserSheet extends StatefulWidget {
  final Function(Map<String, dynamic> parsedData) onConfirm;

  const AiScheduleParserSheet({super.key, required this.onConfirm});

  @override
  State<AiScheduleParserSheet> createState() => _AiScheduleParserSheetState();
}

class _AiScheduleParserSheetState extends State<AiScheduleParserSheet> {
  final TextEditingController _textController = TextEditingController();
  final BirdController _birdController = Get.find();
  Map<String, dynamic>? _parsedResult;
  bool _isParsing = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface2 =>
      _isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
  Color get _input =>
      _isDark ? CustomColor.kDarkInputFill : CustomColor.kTextOnDark;
  Color get _border =>
      _isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
  Color get _text1 =>
      _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
  Color get _text2 =>
      _isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
  Color get _text3 =>
      _isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      Utils.showGetSnackBar('Please enter a description');
      return;
    }

    setState(() => _isParsing = true);
    final result = await _birdController.parseNaturalSchedule(text);
    setState(() {
      _parsedResult = result;
      _isParsing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(AppRadius.xxs.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: CustomColor.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    color: CustomColor.kTextOnDark, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Text(
                'AI Schedule Parser',
                style: AppTextStyles.headingMd.copyWith(color: _text1),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Describe your schedule naturally',
            style: AppTextStyles.subtitle.copyWith(color: _text2),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _textController,
            maxLines: 3,
            minLines: 2,
            style: AppTextStyles.bodyMd.copyWith(color: _text1),
            decoration: InputDecoration(
              hintText:
                  'e.g. "Remind me tomorrow at 3pm to wish John happy birthday"',
              hintStyle: AppTextStyles.subtitle.copyWith(color: _text3),
              filled: true,
              fillColor: _input,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                borderSide: BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                borderSide:
                    BorderSide(color: CustomColor.kPrimaryColor, width: 1.5),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: CustomColor.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.xl.r),
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _isParsing ? null : _parse,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                ),
                child: _isParsing
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CustomColor.kTextOnDark,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 18.r, color: CustomColor.kTextOnDark),
                          SizedBox(width: 8.w),
                          Text(
                            'Parse Schedule',
                            style: AppTextStyles.titleMd
                                .copyWith(color: CustomColor.kTextOnDark),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_parsedResult != null && _parsedResult!.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: _surface2,
                borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                border: Border.all(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: CustomColor.kSuccess, size: 18.r),
                      SizedBox(width: 8.w),
                      Text(
                        'Parsed Result',
                        style: AppTextStyles.titleMd.copyWith(color: _text1),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _ParsedRow(
                    icon: Icons.message_rounded,
                    label: 'Message',
                    value: _parsedResult!['message'] ?? '',
                  ),
                  SizedBox(height: 8.h),
                  _ParsedRow(
                    icon: Icons.calendar_month_rounded,
                    label: 'Date',
                    value: _parsedResult!['date'] ?? '',
                  ),
                  SizedBox(height: 8.h),
                  _ParsedRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _parsedResult!['time'] ?? '',
                  ),
                  if (_parsedResult!['category'] != null) ...[
                    SizedBox(height: 8.h),
                    _ParsedRow(
                      icon: Icons.label_rounded,
                      label: 'Category',
                      value: _parsedResult!['category'],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: CustomColor.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () {
                    if (_parsedResult != null) {
                      widget.onConfirm(_parsedResult!);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                    ),
                  ),
                  child: Text(
                    'Use This Schedule',
                    style: AppTextStyles.titleMd
                        .copyWith(color: CustomColor.kTextOnDark),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ParsedRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ParsedRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface2 =
        isDark ? CustomColor.kDarkSurface2 : CustomColor.kTextOnDark;
    final text1 = isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final text3 =
        isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: surface2,
            borderRadius: BorderRadius.circular(AppRadius.md.r),
          ),
          child: Icon(icon, size: 14.r, color: CustomColor.kPrimaryColor),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(color: text3),
            ),
            Text(
              value,
              style: AppTextStyles.label.copyWith(color: text1),
            ),
          ],
        ),
      ],
    );
  }
}
