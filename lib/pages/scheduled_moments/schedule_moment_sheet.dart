import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/scheduled_moments/upload_progress.dart';
import 'package:humming_bird/controllers/scheduled_moment_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class ScheduleMomentSheet extends StatefulWidget {
  final String content;
  final String? mediaPath;
  final String mediaType;

  const ScheduleMomentSheet({
    super.key,
    required this.content,
    this.mediaPath,
    this.mediaType = 'text',
  });

  @override
  State<ScheduleMomentSheet> createState() => _ScheduleMomentSheetState();
}

class _ScheduleMomentSheetState extends State<ScheduleMomentSheet> {
  final ScheduledMomentController _controller = Get.find();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _visibility = 'everyone';
  int _expiryHours = 24;
  final TextEditingController _captionCtrl = TextEditingController();
  bool _isSaving = false;

  final _visibilities = [
    ('everyone', 'Everyone'),
    ('contacts', 'Contacts'),
    ('family', 'Family'),
    ('close_friends', 'Close Friends'),
    ('only_me', 'Only Me'),
  ];

  final _expiryOptions = [6, 12, 24];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(hours: 1));
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: CustomColor.kPrimaryColor,
              ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: CustomColor.kPrimaryColor,
              ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _schedule() async {
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (scheduledAt.isBefore(DateTime.now())) {
      CustomSnackbar.error(
          title: 'Invalid Time',
          message: 'Scheduled time must be in the future');
      return;
    }

    setState(() => _isSaving = true);
    showUploadProgress(progress: 0.0, statusText: 'Scheduling moment...');

    // On edit, mediaPath holds the remote URL of existing media — only treat
    // it as a local file when it actually exists on disk.
    File? file;
    if (widget.mediaPath != null && widget.mediaPath!.isNotEmpty) {
      final candidate = File(widget.mediaPath!);
      if (candidate.existsSync()) file = candidate;
    }

    final success = await _controller.scheduleMoment(
      content: widget.content,
      file: file,
      mediaType: widget.mediaType,
      scheduledAt: scheduledAt,
      visibility: _visibility,
      expiryHours: _expiryHours,
      caption: _captionCtrl.text.trim(),
    );

    if (mounted) {
      if (success) {
        showUploadProgress(progress: 1.0, statusText: 'Moment scheduled!');
        await Future.delayed(const Duration(milliseconds: 800));
        Get.back();
        Get.back(result: true);
        CustomSnackbar.success(
            title: 'Scheduled', message: 'Your moment is scheduled');
      } else {
        Get.back();
        CustomSnackbar.error(
            title: 'Failed', message: 'Could not schedule moment. Retry?');
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _saveDraft() async {
    setState(() => _isSaving = true);
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final success = await _controller.saveAsDraft(
      content: widget.content,
      mediaPath: widget.mediaPath,
      mediaType: widget.mediaType,
      scheduledAt: scheduledAt,
      visibility: _visibility,
      expiryHours: _expiryHours,
    );
    if (mounted) {
      if (success) {
        Get.back();
        CustomSnackbar.success(
            title: 'Draft Saved', message: 'Your moment draft has been saved');
      } else {
        CustomSnackbar.error(title: 'Failed', message: 'Could not save draft');
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20.w, 12.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CustomColor.kDarkDivider
                        : CustomColor.kLightBorder,
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text('Schedule Moment',
                  style: AppTextStyles.headingMd.copyWith(
                      color: isDark
                          ? CustomColor.kTextOnDark
                          : CustomColor.kTextPrimary)),
              SizedBox(height: 20.h),
              _buildDateTile(isDark),
              SizedBox(height: 12.h),
              _buildTimeTile(isDark),
              SizedBox(height: 12.h),
              _buildVisibilityTile(isDark),
              SizedBox(height: 12.h),
              _buildExpiryTile(isDark),
              SizedBox(height: 12.h),
              TextField(
                controller: _captionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Add a caption (optional)',
                  hintStyle: AppTextStyles.subtitle
                      .copyWith(color: CustomColor.kTextTertiary),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                  filled: true,
                  fillColor: isDark
                      ? CustomColor.kDarkSurface2
                      : CustomColor.kUltraLightBg,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
                style: AppTextStyles.subtitle.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _saveDraft,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl.r)),
                        side: BorderSide(color: CustomColor.kPrimaryColor),
                      ),
                      child: Text('Save Draft',
                          style: AppTextStyles.titleSm
                              .copyWith(color: CustomColor.kPrimaryColor)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _schedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColor.kPrimaryFill,
                        foregroundColor: CustomColor.kTextOnDark,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl.r)),
                        elevation: 2,
                      ),
                      child: Text('Schedule', style: AppTextStyles.titleSm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(bool isDark) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
              color: isDark
                  ? CustomColor.kDarkBorder
                  : CustomColor.kLightBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18.r, color: CustomColor.kPrimaryColor),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date',
                    style: AppTextStyles.labelSm
                        .copyWith(color: CustomColor.kTextTertiary)),
                Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                    style: AppTextStyles.bodyMd.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: CustomColor.kTextTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(bool isDark) {
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
              color: isDark
                  ? CustomColor.kDarkBorder
                  : CustomColor.kLightBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 18.r, color: CustomColor.kPrimaryColor),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time',
                    style: AppTextStyles.labelSm
                        .copyWith(color: CustomColor.kTextTertiary)),
                Text(_selectedTime.format(context),
                    style: AppTextStyles.bodyMd.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: CustomColor.kTextTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityTile(bool isDark) {
    final currentLabel =
        _visibilities.firstWhere((v) => v.$1 == _visibility).$2;
    return GestureDetector(
      onTap: () {
        Get.bottomSheet(
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color:
                  isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CustomColor.kDarkDivider
                            : CustomColor.kLightBorder,
                        borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('Visibility',
                      style: AppTextStyles.headingMd.copyWith(
                          color: isDark
                              ? CustomColor.kTextOnDark
                              : CustomColor.kTextPrimary)),
                  SizedBox(height: 12.h),
                  ..._visibilities.map((v) => ListTile(
                        leading: Icon(
                          _visibility == v.$1
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: CustomColor.kPrimaryColor,
                        ),
                        title: Text(v.$2,
                            style: GoogleFonts.poppins(
                                color: isDark
                                    ? CustomColor.kTextOnDark
                                    : CustomColor.kTextPrimary)),
                        onTap: () {
                          setState(() => _visibility = v.$1);
                          Get.back();
                        },
                      )),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
              color: isDark
                  ? CustomColor.kDarkBorder
                  : CustomColor.kLightBorder.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.visibility_rounded,
                size: 18.r, color: CustomColor.kPrimaryColor),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Visibility',
                    style: AppTextStyles.labelSm
                        .copyWith(color: CustomColor.kTextTertiary)),
                Text(currentLabel,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: CustomColor.kTextTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryTile(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        border: Border.all(
            color: isDark
                ? CustomColor.kDarkBorder
                : CustomColor.kLightBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined,
              size: 18.r, color: CustomColor.kPrimaryColor),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Expires after',
                  style: AppTextStyles.labelSm
                      .copyWith(color: CustomColor.kTextTertiary)),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _expiryHours,
                  dropdownColor: isDark
                      ? CustomColor.kDarkSurface2
                      : CustomColor.kTextOnDark,
                  items: _expiryOptions
                      .map((h) => DropdownMenuItem(
                            value: h,
                            child: Text('$h hours',
                                style: AppTextStyles.bodyMd.copyWith(
                                    color: isDark
                                        ? CustomColor.kTextOnDark
                                        : CustomColor.kTextPrimary)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _expiryHours = v);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
