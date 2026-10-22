import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

/// Shared reschedule dialog (date/time/interval/count) used by the Schedule
/// tab, the Scheduled Message Details screen and the chat bubble menu.
class RescheduleDialog extends StatefulWidget {
  final Messages message;

  const RescheduleDialog({super.key, required this.message});

  @override
  State<RescheduleDialog> createState() => _RescheduleDialogState();
}

class _RescheduleDialogState extends State<RescheduleDialog> {
  late DateTime _dateTime;
  late int _interval;
  late int _count;
  bool _saving = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
  Color get _surface2 =>
      _isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
  Color get _input =>
      _isDark ? CustomColor.kDarkInputFill : CustomColor.kTextOnDark;
  Color get _title =>
      _isDark ? CustomColor.kTextOnDark : CustomColor.kDarkSecondaryColor;
  Color get _text2 =>
      _isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;

  @override
  void initState() {
    super.initState();
    final epoch = int.tryParse(widget.message.mScheduledAt ?? '');
    _dateTime = epoch == null
        ? DateTime.now().add(const Duration(minutes: 5))
        : DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    _interval = int.tryParse(widget.message.interval ?? '0') ?? 0;
    _count = int.tryParse(widget.message.count ?? '0') ?? 0;
    if (_count < 0) _count = 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    if (DateTime.now().isAfter(_dateTime)) {
      Utils.showGetSnackBar('Please choose a future date and time');
      return;
    }

    setState(() => _saving = true);
    final BirdController birdController = Get.find();
    final success = await birdController.rescheduleMessage(
      message: widget.message,
      scheduledAt: _dateTime,
      interval: _interval,
      count: _count,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(AppRadius.rounded.r),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    gradient: CustomColor.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(Icons.event_repeat_rounded,
                      color: CustomColor.kTextOnDark, size: 22.r),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Reschedule message',
                  style: AppTextStyles.headingMd.copyWith(color: _title),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: _DialogAction(
                    icon: Icons.calendar_month_rounded,
                    label: DateFormat('MMM dd, yyyy').format(_dateTime),
                    onTap: _pickDate,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _DialogAction(
                    icon: Icons.access_time_rounded,
                    label: DateFormat('h:mm a').format(_dateTime),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text('Repeat interval',
                style: AppTextStyles.label.copyWith(color: _text2)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                const _RepeatChip(label: 'Once', value: 0),
                const _RepeatChip(label: 'Daily', value: 1),
                const _RepeatChip(label: 'Weekly', value: 2),
                const _RepeatChip(label: 'Monthly', value: 3),
                const _RepeatChip(label: 'Yearly', value: 4),
              ]
                  .map(
                    (chip) => ChoiceChip(
                      label: Text(chip.label,
                          style: AppTextStyles.bodySm.copyWith(
                              color: _interval == chip.value
                                  ? CustomColor.kTextOnDark
                                  : _title)),
                      selected: _interval == chip.value,
                      selectedColor: CustomColor.kPrimaryFill,
                      backgroundColor: _surface2,
                      onSelected: (_) => setState(() {
                        _interval = chip.value;
                        if (_interval == 0) _count = 0;
                      }),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg.r)),
                    ),
                  )
                  .toList(),
            ),
            if (_interval > 0) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: _surface2,
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                  border: Border.all(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _count == 0
                            ? 'Repeat count: Forever'
                            : 'Repeat count: $_count',
                        style: AppTextStyles.subtitle.copyWith(color: _title),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Decrease repeat count',
                      onPressed: () {
                        if (_count > 0) setState(() => _count--);
                      },
                      icon: Icon(Icons.remove_circle_outline_rounded,
                          color: CustomColor.kPrimaryColor),
                    ),
                    Container(
                      width: 48.w,
                      height: 36.h,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _input,
                        borderRadius: BorderRadius.circular(AppRadius.lg.r),
                        border: Border.all(
                            color: CustomColor.kPrimaryColor
                                .withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _count == 0 ? '∞' : '$_count',
                        style: AppTextStyles.titleMd
                            .copyWith(color: CustomColor.kPrimaryColor),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Increase repeat count',
                      onPressed: () => setState(() => _count++),
                      icon: Icon(Icons.add_circle_outline_rounded,
                          color: CustomColor.kPrimaryColor),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: CustomColor.kPrimaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(
                            color: CustomColor.primaryTextFor(_isDark),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: CustomColor.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.xl.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CustomColor.kTextOnDark,
                              ),
                            )
                          : Text('Save',
                              style: GoogleFonts.poppins(
                                  color: CustomColor.kTextOnDark,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DialogAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark
              ? CustomColor.kDarkSurface2
              : CustomColor.kUltraLightPrimary,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          border: Border.all(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                gradient: CustomColor.primaryGradient,
                borderRadius: BorderRadius.circular(AppRadius.md.r),
              ),
              child: Icon(icon, color: CustomColor.kTextOnDark, size: 16.r),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDark
                        : CustomColor.kDarkSecondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatChip {
  final String label;
  final int value;

  const _RepeatChip({required this.label, required this.value});
}
