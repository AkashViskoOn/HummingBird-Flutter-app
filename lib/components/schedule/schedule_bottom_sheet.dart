import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/schedule/counter_button.dart';
import 'package:humming_bird/components/schedule/pick_date_field.dart';
import 'package:humming_bird/components/schedule/pick_time_field.dart';
import 'package:humming_bird/components/schedule/schedule_intervals.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/emoji_picker.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ScheduleBottomSheet extends StatelessWidget {
  final bool generatedMessage;
  const ScheduleBottomSheet({super.key, this.generatedMessage = false});

  @override
  Widget build(BuildContext context) {
    BirdController birdController = Get.find();
    ChatController chatController = Get.find();
    chatController.scheduleOn = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
    final surface2 =
        isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
    final border = isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
    final text1 = isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final text2 =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
    final text3 =
        isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;
    return PopScope(
      onPopInvokedWithResult: (_, __) {
        chatController.toggleSendButton.value = false;
        chatController.scheduleOn = false;
        chatController.dateController.clear();
        chatController.timeController.clear();
      },
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: BottomSheet(
          onClosing: () {},
          enableDrag: false,
          builder: (context) {
            return Container(
              height:
                  context.height < 900 ? Get.height * 0.68 : Get.height * 0.56,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
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
                          child: Icon(
                            Icons.calendar_today_sharp,
                            color: CustomColor.kTextOnDark,
                            size: 22.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Schedule Message',
                          style: AppTextStyles.headingLg.copyWith(color: text1),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16.h,
                    ),
                    Row(
                      children: [
                        Text(
                          'Repeat message ?',
                          style: AppTextStyles.headingSm.copyWith(color: text1),
                        ),
                        Text(
                          ' (Optional)',
                          style: AppTextStyles.bodyMd.copyWith(color: text3),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 12.h,
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(() => ScheduleIntervals(
                                onTap: () =>
                                    chatController.selectScheduleInterval(1),
                                label: 'Daily',
                                isSelected:
                                    chatController.selectedInterval.value == 1,
                              )),
                          Obx(() => ScheduleIntervals(
                                onTap: () =>
                                    chatController.selectScheduleInterval(2),
                                isSelected:
                                    chatController.selectedInterval.value == 2,
                                label: 'Weekly',
                              )),
                          Obx(() => ScheduleIntervals(
                                onTap: () =>
                                    chatController.selectScheduleInterval(3),
                                isSelected:
                                    chatController.selectedInterval.value == 3,
                                label: 'Monthly',
                              )),
                          Obx(() => ScheduleIntervals(
                                onTap: () =>
                                    chatController.selectScheduleInterval(4),
                                isSelected:
                                    chatController.selectedInterval.value == 4,
                                label: 'Yearly',
                              )),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 16.h,
                    ),
                    FittedBox(
                      child: Text(
                        'How many times you want to repeat message',
                        style: AppTextStyles.headingSm.copyWith(color: text2),
                      ),
                    ),
                    SizedBox(
                      height: 12.h,
                    ),
                    Row(
                      children: [
                        Obx(
                          () => Container(
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.fifteen.r),
                              border: Border.all(
                                color: chatController.scheduleCount.value == 0
                                    ? CustomColor.kPrimaryColor
                                        .withValues(alpha: 0.2)
                                    : border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: chatController.scheduleCount.value == 0
                                      ? CustomColor.kPrimaryColor
                                          .withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value:
                                      chatController.scheduleCount.value == 0,
                                  activeColor: CustomColor.kPrimaryColor,
                                  onChanged: (value) {
                                    chatController.scheduleCount.value = 0;
                                  },
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      chatController.scheduleCount.value = 0,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 12.w),
                                    child: Text(
                                      'Forever',
                                      style: AppTextStyles.headingSm
                                          .copyWith(color: text1),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'OR',
                          style: AppTextStyles.headingMd.copyWith(color: text3),
                        ),
                        const Spacer(),
                        CounterButton(
                            tooltip: 'More',
                            onTap: () {
                              chatController.scheduleCount.value++;
                            },
                            icon: Icon(
                              Icons.add,
                              color: CustomColor.kTextOnDark,
                              size: 25.r,
                            )),
                        SizedBox(
                          width: 5.w,
                        ),
                        Obx(() => AnimatedFlipCounter(
                              duration: const Duration(milliseconds: 250),
                              value: chatController.scheduleCount.value,
                              textStyle: AppTextStyles.headingLg
                                  .copyWith(color: CustomColor.kPrimaryColor),
                            )),
                        SizedBox(
                          width: 5.w,
                        ),
                        CounterButton(
                            tooltip: 'Fewer',
                            onTap: () {
                              if (chatController.scheduleCount.value > 0) {
                                chatController.scheduleCount.value--;
                              }
                            },
                            icon: Icon(
                              Icons.remove,
                              color: CustomColor.kTextOnDark,
                              size: 25.r,
                            )),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    const PickDateField(
                      fromBottomSheet: true,
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    const PickTimeField(
                      fromBottomSheet: true,
                    ),
                    SizedBox(
                      height: 30.h,
                    ),
                    generatedMessage
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              AppButton(
                                text: 'Cancel',
                                onTap: () => Get.back(),
                                buttonSize: Size(Get.width * 0.4, 45),
                                backgroundColor: CustomColor.kDarkPrimaryColor,
                              ),
                              AppButton(
                                text: 'Schedule',
                                onTap: () => chatController.setDateAndTime(
                                    aiGenerated: true),
                                backgroundColor: CustomColor.kDarkPrimaryColor,
                                buttonSize: Size(Get.width * 0.4, 45),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Divider(color: border, height: 1.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Obx(() => InkWell(
                                        onTap: () {
                                          if (!chatController
                                              .uploadingFile.value) {
                                            showModalBottomSheet(
                                              context: context,
                                              useSafeArea: true,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.vertical(
                                                        top: Radius.circular(
                                                            24.r)),
                                              ),
                                              builder: (context) {
                                                return Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      24.w, 16.h, 24.w, 24.h),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      Container(
                                                        width: 40.w,
                                                        height: 4.h,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: border,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      2.r),
                                                        ),
                                                      ),
                                                      SizedBox(height: 20.h),
                                                      ListTile(
                                                        leading: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  8.r),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: surface2,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.r),
                                                          ),
                                                          child: Icon(
                                                              Icons.photo,
                                                              color: CustomColor
                                                                  .kPrimaryColor),
                                                        ),
                                                        title: Text('Photo',
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color:
                                                                        text1)),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.r)),
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                          chatController.pickFile(
                                                              FileType.image, 1,
                                                              fromScheduleScreen:
                                                                  true);
                                                        },
                                                      ),
                                                      ListTile(
                                                        leading: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  8.r),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: surface2,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.r),
                                                          ),
                                                          child: Icon(
                                                              Icons.videocam,
                                                              color: CustomColor
                                                                  .kPrimaryColor),
                                                        ),
                                                        title: Text('Video',
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color:
                                                                        text1)),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.r)),
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                          chatController.pickFile(
                                                              FileType.video, 4,
                                                              fromScheduleScreen:
                                                                  true);
                                                        },
                                                      ),
                                                      ListTile(
                                                        leading: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  8.r),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: surface2,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.r),
                                                          ),
                                                          child: Icon(
                                                              Icons
                                                                  .edit_document,
                                                              color: CustomColor
                                                                  .kPrimaryColor),
                                                        ),
                                                        title: Text('Document',
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color:
                                                                        text1)),
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.r)),
                                                        onTap: () {
                                                          Navigator.pop(
                                                              context);
                                                          chatController.pickFile(
                                                              FileType.any, 2,
                                                              fromScheduleScreen:
                                                                  true);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                        },
                                        child: chatController
                                                .uploadingFile.value
                                            ? Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CircularProgressIndicator(
                                                    value: birdController
                                                        .uploadValue.value,
                                                    color: CustomColor
                                                        .kPrimaryColor,
                                                  ),
                                                  Icon(
                                                    Icons.cloud_upload,
                                                    size: 25.r,
                                                    color: CustomColor
                                                        .kPrimaryColor,
                                                  ),
                                                ],
                                              )
                                            : Icon(
                                                Icons
                                                    .add_circle_outline_rounded,
                                                color:
                                                    CustomColor.kPrimaryColor,
                                                size: 35.r,
                                              ),
                                      )),
                                  SizedBox(
                                    width: 10.w,
                                  ),
                                  Flexible(
                                    child: TextField(
                                      cursorColor: CustomColor.kPrimaryColor,
                                      controller:
                                          chatController.textMessageController,
                                      keyboardType: TextInputType.multiline,
                                      minLines: 1,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            EdgeInsets.only(top: 12.h),
                                        hintText: 'Type a message...',
                                        hintStyle: AppTextStyles.headingSm
                                            .copyWith(color: text3),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: CustomColor.kPrimaryColor,
                                              width: 1.5),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.thirty.r),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: CustomColor.kPrimaryColor,
                                              width: 2),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.thirty.r),
                                        ),
                                        prefixIcon: Obx(
                                          () => IconButton(
                                            tooltip: 'Emoji',
                                            onPressed: () {
                                              final shouldOpen = !chatController
                                                  .showEmojiPicker.value;
                                              if (shouldOpen) {
                                                FocusManager
                                                    .instance.primaryFocus
                                                    ?.unfocus();
                                              }
                                              chatController.showEmojiPicker
                                                  .value = shouldOpen;
                                            },
                                            icon: Icon(
                                              Icons.emoji_emotions_outlined,
                                              size: 22.sp,
                                              color: chatController
                                                      .showEmojiPicker.value
                                                  ? CustomColor.kPrimaryColor
                                                  : CustomColor.kGoldAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  GestureDetector(
                                      onTap: () {
                                        chatController
                                            .sendMessageOrAudio(context);
                                      },
                                      // onLongPress: () {
                                      //   if (chatController
                                      //           .toggleSendButton.value ==
                                      //       false) {
                                      //     chatController.recordAudio();
                                      //   }
                                      // },
                                      // onLongPressEnd: (details) {
                                      //   if (chatController
                                      //           .toggleSendButton.value ==
                                      //       false) {
                                      //     chatController.saveAudio();
                                      //   }
                                      // },
                                      child: Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                            gradient:
                                                CustomColor.primaryGradient,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: CustomColor.kPrimaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]),
                                        child: Obx(
                                          () => Icon(
                                              chatController
                                                      .toggleSendButton.value
                                                  ? Icons.send
                                                  : Icons.mic,
                                              size: chatController
                                                      .toggleSendButton.value
                                                  ? 32.r
                                                  : chatController
                                                      .audioIconSize.value,
                                              color: CustomColor.kTextOnDark),
                                        ),
                                      )),
                                ],
                              ),
                              Divider(color: border, height: 1.h),
                              Obx(
                                () => chatController.showEmojiPicker.value
                                    ? const EmojiPickerSheet()
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          )
                    // SizedBox(
                    //   height: 15.h,
                    // ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //   children: [
                    //     Flexible(
                    //       child: AppButton(
                    //         text: context.width < 400
                    //             ? 'Cancel'
                    //             : 'Cancel Schedule',
                    //         backgroundColor: CustomColor.kDarkPrimaryColor,
                    //         onTap: () {
                    //           chatController.isScheduledMessage.value = '0';
                    //           Get.back();
                    //         },
                    //       ),
                    //     ),
                    //     const SizedBox(
                    //       width: 20,
                    //     ),
                    //     Flexible(
                    //       child: AppButton(
                    //         text: 'Schedule',
                    //         backgroundColor: CustomColor.kDarkPrimaryColor,
                    //         onTap: () {
                    //           chatController.setDateAndTime();
                    //           Get.back();
                    //         },
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// In-screen schedule panel that slides up above the chat composer so the
/// composer (mic, emoji, attach, camera) stays visible and usable underneath.
class ScheduleSheetOverlay extends StatelessWidget {
  final double bottomInset;
  const ScheduleSheetOverlay({super.key, this.bottomInset = 90});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find();
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: bottomInset,
      child: ClipRect(
        child: Obx(() {
          final visible = chatController.scheduleSheetVisible.value;
          return AnimatedPadding(
            padding: EdgeInsets.only(bottom: visible ? 0 : 480.h),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: visible ? chatController.closeScheduleSheet : null,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Container(
                      color: CustomColor.kDarkBackground.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedOpacity(
                    opacity: visible ? 1 : 0,
                    duration: const Duration(milliseconds: 240),
                    child: IgnorePointer(
                      ignoring: !visible,
                      child: _ScheduleSheetPanel(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ScheduleSheetPanel extends StatefulWidget {
  const _ScheduleSheetPanel();

  @override
  State<_ScheduleSheetPanel> createState() => _ScheduleSheetPanelState();
}

class _ScheduleSheetPanelState extends State<_ScheduleSheetPanel>
    with SingleTickerProviderStateMixin {
  final ChatController chatController = Get.find();
  final BirdController birdController = Get.find();
  late final AnimationController _slideCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
  double _dragOffset = 0;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface =>
      _isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
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

  void _showScheduleAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: _surface2,
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(Icons.photo, color: CustomColor.kPrimaryColor),
                ),
                title: Text('Photo',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: _text1)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                onTap: () {
                  Navigator.pop(context);
                  chatController.pickFile(FileType.image, 1,
                      fromScheduleScreen: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: _surface2,
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(Icons.videocam, color: CustomColor.kPrimaryColor),
                ),
                title: Text('Video',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: _text1)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                onTap: () {
                  Navigator.pop(context);
                  chatController.pickFile(FileType.video, 4,
                      fromScheduleScreen: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: _surface2,
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(Icons.edit_document,
                      color: CustomColor.kPrimaryColor),
                ),
                title: Text('Document',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, color: _text1)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                onTap: () {
                  Navigator.pop(context);
                  chatController.pickFile(FileType.any, 2,
                      fromScheduleScreen: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    chatController.dateController.addListener(_onFieldsChanged);
    chatController.timeController.addListener(_onFieldsChanged);
    chatController.textMessageController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    chatController.dateController.removeListener(_onFieldsChanged);
    chatController.timeController.removeListener(_onFieldsChanged);
    chatController.textMessageController.removeListener(_onFieldsChanged);
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  void _applyPreset(DateTime date, TimeOfDay time) {
    chatController.pickedDate = date;
    chatController.pickedTime = time;
    chatController.dateController.text =
        DateFormat('EEE, d MMM yyyy').format(date);
    chatController.timeController.text = time.format(context);
    setState(() {});
  }

  void _clearSchedule() {
    chatController.pickedDate = null;
    chatController.pickedTime = null;
    chatController.dateController.clear();
    chatController.timeController.clear();
  }

  bool _isPresetActive(DateTime date, TimeOfDay time) {
    final d = chatController.pickedDate;
    final t = chatController.pickedTime;
    return d != null &&
        t != null &&
        d.year == date.year &&
        d.month == date.month &&
        d.day == date.day &&
        t.hour == time.hour &&
        t.minute == time.minute;
  }

  DateTime _guardFuture(DateTime date, int hour, int minute) {
    final candidate = DateTime(date.year, date.month, date.day, hour, minute);
    return candidate.isAfter(DateTime.now())
        ? candidate
        : candidate.add(const Duration(days: 1));
  }

  DateTime _nextWeekday(int targetWeekday, int hour, int minute) {
    final now = DateTime.now();
    var days = (targetWeekday - now.weekday + 7) % 7;
    if (days == 0) days = 7;
    final candidate =
        DateTime(now.year, now.month, now.day + days, hour, minute);
    return candidate.isAfter(DateTime.now())
        ? candidate
        : candidate.add(const Duration(days: 7));
  }

  Widget _presetChip(String label, TimeOfDay time) {
    final DateTime date;
    if (label == 'Tonight') {
      date = _guardFuture(DateTime.now(), time.hour, time.minute);
    } else if (label == 'Tomorrow') {
      final now = DateTime.now();
      date = DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
    } else {
      date = _nextWeekday(DateTime.friday, time.hour, time.minute);
    }
    final selected = _isPresetActive(date, time);
    return Expanded(
      child: InkWell(
        onTap: () => _applyPreset(date, time),
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 7.h),
          decoration: BoxDecoration(
            color: selected ? CustomColor.kPrimaryColor : _surface2,
            borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
            border: Border.all(
              color: selected ? CustomColor.kPrimaryColor : _border,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: CustomColor.kPrimaryGlow,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySm
                .copyWith(color: selected ? CustomColor.kTextOnDark : _text2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSchedule = chatController.dateController.text.isNotEmpty &&
        chatController.timeController.text.isNotEmpty;
    final String preview = chatController.textMessageController.text.trim();
    final String dateLabel = chatController.pickedDate != null
        ? DateFormat('EEE, d MMM yyyy').format(chatController.pickedDate!)
        : chatController.dateController.text;
    final String timeLabel = chatController.pickedTime != null
        ? chatController.pickedTime!.format(context)
        : chatController.timeController.text;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 560.0);
        });
      },
      onVerticalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;
        if (_dragOffset > 110 || velocity > 700) {
          _slideCtrl.forward().whenComplete(() {
            if (mounted) chatController.closeScheduleSheet();
          });
        } else {
          _slideCtrl.reverse();
          setState(() => _dragOffset = 0);
        }
      },
      onVerticalDragCancel: () => setState(() => _dragOffset = 0),
      child: AnimatedBuilder(
        animation: _slideCtrl,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _dragOffset + _slideCtrl.value * 560),
          child: child,
        ),
        child: Container(
          width: double.infinity,
          height: (MediaQuery.of(context).size.height -
                  MediaQuery.of(context).viewInsets.bottom) *
              0.7,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Fixed header ──
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
                child: Column(
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
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(9.r),
                          decoration: BoxDecoration(
                            gradient: CustomColor.primaryGradient,
                            borderRadius: BorderRadius.circular(AppRadius.xl.r),
                          ),
                          child: Icon(
                            Icons.calendar_today_sharp,
                            color: CustomColor.kTextOnDark,
                            size: 20.r,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Schedule Message',
                          style: AppTextStyles.titleLg.copyWith(color: _text1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
// ── Scrollable options ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section 1 — scheduled status + message preview
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: hasSchedule
                                      ? Container(
                                          key: const ValueKey(
                                              'scheduled-status'),
                                          margin: EdgeInsets.only(top: 12.h),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12.w, vertical: 8.h),
                                          decoration: BoxDecoration(
                                            color: CustomColor.kSuccess
                                                .withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.xl.r),
                                            border: Border.all(
                                              color: CustomColor.kSuccess
                                                  .withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.event_available_rounded,
                                                size: 18.r,
                                                color: CustomColor.kSuccess,
                                              ),
                                              SizedBox(width: 8.w),
                                              Expanded(
                                                child: Text(
                                                  'Scheduled for $dateLabel · $timeLabel',
                                                  style: AppTextStyles.bodySm
                                                      .copyWith(color: _text1),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: _clearSchedule,
                                                child: Text(
                                                  'Remove',
                                                  style: AppTextStyles.bodySm
                                                      .copyWith(
                                                          color: CustomColor
                                                              .kDangerRed),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: _surface2,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.fourteen.r),
                                    border: Border.all(
                                      color: _border,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        size: 20.r,
                                        color: CustomColor.kPrimaryColor,
                                      ),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: preview.isEmpty
                                            ? Text(
                                                'Type a message to schedule it…',
                                                style: AppTextStyles.subtitle
                                                    .copyWith(color: _text3),
                                              )
                                            : Text(
                                                preview,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.bodyMd
                                                    .copyWith(color: _text1),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Section 2 — repeat + count
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Text(
                                      'Repeat message ?',
                                      style: AppTextStyles.titleMd
                                          .copyWith(color: _text1),
                                    ),
                                    Text(
                                      ' (Optional)',
                                      style: AppTextStyles.subtitle
                                          .copyWith(color: _text3),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Obx(() => ScheduleIntervals(
                                            onTap: () => chatController
                                                .selectScheduleInterval(1),
                                            label: 'Daily',
                                            isSelected: chatController
                                                    .selectedInterval.value ==
                                                1,
                                          )),
                                      Obx(() => ScheduleIntervals(
                                            onTap: () => chatController
                                                .selectScheduleInterval(2),
                                            label: 'Weekly',
                                            isSelected: chatController
                                                    .selectedInterval.value ==
                                                2,
                                          )),
                                      Obx(() => ScheduleIntervals(
                                            onTap: () => chatController
                                                .selectScheduleInterval(3),
                                            label: 'Monthly',
                                            isSelected: chatController
                                                    .selectedInterval.value ==
                                                3,
                                          )),
                                      Obx(() => ScheduleIntervals(
                                            onTap: () => chatController
                                                .selectScheduleInterval(4),
                                            label: 'Yearly',
                                            isSelected: chatController
                                                    .selectedInterval.value ==
                                                4,
                                          )),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 14.h),
                                FittedBox(
                                  child: Text(
                                    'How many times you want to repeat message',
                                    style: AppTextStyles.bodyMd
                                        .copyWith(color: _text2),
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Obx(
                                      () => Container(
                                        decoration: BoxDecoration(
                                          color: _surface,
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.xl.r),
                                          border: Border.all(
                                            color: chatController
                                                        .scheduleCount.value ==
                                                    0
                                                ? CustomColor.kPrimaryColor
                                                    .withValues(alpha: 0.2)
                                                : _border,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: chatController
                                                          .scheduleCount
                                                          .value ==
                                                      0
                                                  ? CustomColor.kPrimaryColor
                                                      .withValues(alpha: 0.06)
                                                  : Colors.black
                                                      .withValues(alpha: 0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: chatController
                                                      .scheduleCount.value ==
                                                  0,
                                              activeColor:
                                                  CustomColor.kPrimaryColor,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              onChanged: (value) {
                                                chatController
                                                    .scheduleCount.value = 0;
                                              },
                                            ),
                                            GestureDetector(
                                              onTap: () => chatController
                                                  .scheduleCount.value = 0,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    right: 12.w),
                                                child: Text(
                                                  'Forever',
                                                  style: AppTextStyles.bodyMd
                                                      .copyWith(color: _text1),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'OR',
                                      style: AppTextStyles.bodyMd
                                          .copyWith(color: _text3),
                                    ),
                                    const Spacer(),
                                    CounterButton(
                                        tooltip: 'More',
                                        onTap: () {
                                          chatController.scheduleCount.value++;
                                        },
                                        icon: Icon(
                                          Icons.add,
                                          color: CustomColor.kTextOnDark,
                                          size: 18.r,
                                        )),
                                    SizedBox(width: 6.w),
                                    Obx(() => AnimatedFlipCounter(
                                          duration:
                                              const Duration(milliseconds: 250),
                                          value: chatController
                                              .scheduleCount.value,
                                          textStyle: AppTextStyles.headingMd
                                              .copyWith(
                                                  color: CustomColor
                                                      .kPrimaryColor),
                                        )),
                                    SizedBox(width: 6.w),
                                    CounterButton(
                                        tooltip: 'Fewer',
                                        onTap: () {
                                          if (chatController
                                                  .scheduleCount.value >
                                              0) {
                                            chatController
                                                .scheduleCount.value--;
                                          }
                                        },
                                        icon: Icon(
                                          Icons.remove,
                                          color: CustomColor.kTextOnDark,
                                          size: 18.r,
                                        )),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            // Section 3 — date & time
                            Row(
                              children: [
                                const Expanded(
                                  child: PickDateField(fromBottomSheet: true),
                                ),
                                SizedBox(width: 10.w),
                                const Expanded(
                                  child: PickTimeField(fromBottomSheet: true),
                                ),
                              ],
                            ),
                            // Section 4 - quick pick
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 12.h),
                                Text(
                                  'Quick pick',
                                  style: AppTextStyles.subtitle
                                      .copyWith(color: _text2),
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  children: [
                                    _presetChip('Tonight',
                                        const TimeOfDay(hour: 21, minute: 0)),
                                    SizedBox(width: 8.w),
                                    _presetChip('Tomorrow',
                                        const TimeOfDay(hour: 9, minute: 0)),
                                    SizedBox(width: 8.w),
                                    _presetChip('This Friday',
                                        const TimeOfDay(hour: 18, minute: 0)),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                              ],
                            ),
                            // Section 5 - save as draft
                            GestureDetector(
                              onTap: () => chatController.saveScheduleAsDraft(),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 10.h, horizontal: 12.w),
                                decoration: BoxDecoration(
                                  color: _surface2,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.fourteen.r),
                                  border: Border.all(color: _border),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_note_rounded,
                                        size: 18.r,
                                        color: CustomColor.kPrimaryColor),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Save as Draft',
                                      style: AppTextStyles.label.copyWith(
                                          color: _isDark
                                              ? CustomColor.kTextOnDark
                                              : CustomColor
                                                  .kDarkSecondaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // ── Fixed composer (chat-screen style) ──
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w,
                    MediaQuery.of(context).padding.bottom + 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Obx(() => InkWell(
                          onTap: () {
                            if (!chatController.uploadingFile.value) {
                              _showScheduleAttachmentOptions(context);
                            }
                          },
                          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                          child: chatController.uploadingFile.value
                              ? Padding(
                                  padding: EdgeInsets.all(6.r),
                                  child: SizedBox(
                                    width: 20.r,
                                    height: 20.r,
                                    child: CircularProgressIndicator(
                                      value: birdController.uploadValue.value,
                                      color: CustomColor.kPrimaryColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: EdgeInsets.all(6.r),
                                  child: Icon(
                                    Icons.attach_file_rounded,
                                    color: CustomColor.kPrimaryColor,
                                    size: 24.r,
                                  ),
                                ),
                        )),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: TextField(
                        cursorColor: CustomColor.kPrimaryMedium,
                        controller: chatController.textMessageController,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _input,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 11.h),
                          hintText: 'Type a message...',
                          hintStyle:
                              AppTextStyles.bodyLg.copyWith(color: _text3),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Colors.transparent, width: 1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.thirty.r),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: CustomColor.kPrimaryMedium
                                    .withValues(alpha: 0.6),
                                width: 1.4),
                            borderRadius:
                                BorderRadius.circular(AppRadius.thirty.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        if (chatController.isRecording.value) {
                          chatController.saveAudio();
                        } else if (chatController.toggleSendButton.value) {
                          chatController.setDateAndTime();
                        } else {
                          chatController.sendMessageOrAudio(context);
                        }
                      },
                      child: Container(
                        width: 42.r,
                        height: 42.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              CustomColor.kPrimaryColor,
                              CustomColor.kPrimaryMedium,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.twentyTwo.r),
                          boxShadow: [
                            BoxShadow(
                              color: CustomColor.kPrimaryColor
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Obx(
                          () => Icon(
                            chatController.isRecording.value
                                ? Icons.stop_rounded
                                : chatController.toggleSendButton.value
                                    ? Icons.send_rounded
                                    : Icons.mic_rounded,
                            size: 24.r,
                            color: CustomColor.kTextOnDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
