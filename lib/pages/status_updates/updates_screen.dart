import 'dart:async';
import 'dart:io';
import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/components/scheduled_moments/moment_card.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/scheduled_moment_controller.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/scheduled_moments/schedule_moment_sheet.dart';
import 'package:humming_bird/pages/scheduled_moments/scheduled_moments_page.dart';
import 'package:humming_bird/pages/status_updates/status_create_sheet.dart';
import 'package:humming_bird/pages/status_updates/status_viewer_screen.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/pages/status_v2/status_viewers_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _showArchived = false;
  late UserController _userController;
  late StatusController _statusController;
  late ContactController _contactController;
  late ScheduledMomentController _momentController;
  BirdController? _birdController;
  Timer? _countdownTicker;

  static const _availabilities = [
    'Available',
    'Busy',
    'In Meeting',
    'Focus Mode',
    'Travelling',
    'Offline',
  ];

  @override
  void initState() {
    super.initState();
    _userController = Get.find();
    // GetX reuses the permanent StatusController/ScheduledMomentController
    // instances across a re-login (MainHummingScreen is recreated but their
    // onInit/refreshAll runs only on the very first registration). After a
    // logout the resetAccountData wipe leaves the status feed empty for the
    // new account until the user manually pulls-to-refresh, so re-run the
    // refresh explicitly whenever these controllers already exist.
    final reLogin = Get.isRegistered<StatusController>();
    _statusController = Get.put(StatusController(), permanent: true);
    _contactController = Get.find();
    _momentController = Get.put(ScheduledMomentController(), permanent: true);
    if (reLogin) {
      // Defer past the first frame: refreshAll sets Rx values synchronously
      // (isLoading.value = true, myUpdate.value = …) and notifying an Obx
      // while this screen is still building throws "setState() or
      // markNeedsBuild() called during build" for the stale Obx states left
      // over from the previous visit.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _statusController.refreshAll();
        _momentController.refreshAll();
      });
    }
    try {
      _birdController = Get.find<BirdController>();
    } catch (_) {}
    // Keeps the "in 2h 15m" countdowns on scheduled story cards fresh.
    _countdownTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _statusController.refreshAll();
  }

  void _showCreateSheet() {
    Get.bottomSheet(
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      const StatusCreateSheet(),
    );
  }

  void _openMyStatuses() {
    final statuses =
        _statusController.myStatuses.where((s) => !s.isExpired).toList();
    if (statuses.isEmpty) {
      _showCreateSheet();
      return;
    }
    Get.to(() => StatusViewerScreen(
          updates: [],
          initialIndex: 0,
          myStatuses: statuses,
          myUser: _userController.user?.toJson(),
        ));
  }

  void _showMyStatusActions(StatusModel latest) {
    Get.bottomSheet(
      backgroundColor:
          Get.isDarkMode ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      Container(
        padding: EdgeInsets.all(20.r),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    Icon(Icons.edit_rounded, color: CustomColor.kPrimaryColor),
                title: Text('Edit status', style: GoogleFonts.poppins()),
                onTap: () {
                  Get.back();
                  _showUpdateSheet(
                    edit: true,
                    existingContent: latest.suContent ?? '',
                    updateId: latest.suId,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.visibility_rounded,
                    color: CustomColor.kPrimaryColor),
                title: Text('View viewers', style: GoogleFonts.poppins()),
                onTap: () {
                  Get.back();
                  Get.to(() => StatusViewersScreen(status: latest));
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.delete_rounded, color: CustomColor.kDangerRed),
                title: Text('Delete status',
                    style: GoogleFonts.poppins(
                        color: CustomColor.dangerTextFor(Get.isDarkMode))),
                onTap: () {
                  Get.back();
                  _showDeleteConfirm(latest.suId!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateSheet(
      {bool edit = false, String? existingContent, String? updateId}) {
    final textCtrl = TextEditingController(text: existingContent ?? '');
    File? pickedFile;
    String mediaType = 'text';

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor:
          Get.isDarkMode ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w,
            MediaQuery.of(Get.context!).viewInsets.bottom + 20.h),
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
                      color: Get.isDarkMode
                          ? CustomColor.kDarkDivider
                          : CustomColor.kLightBorder,
                      borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  edit ? 'Edit Update' : 'Share an Update',
                  style: AppTextStyles.headingMd.copyWith(
                      color: Get.isDarkMode
                          ? CustomColor.kTextOnDark
                          : CustomColor.kTextPrimary),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                    filled: true,
                    fillColor: Get.isDarkMode
                        ? CustomColor.kDarkSurface2
                        : CustomColor.kUltraLightBg,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _MediaChip(
                      icon: Icons.image_rounded,
                      label: 'Image',
                      onTap: () async {
                        final result =
                            await FilePicker.pickFiles(type: FileType.image);
                        if (result != null &&
                            result.files.single.path != null) {
                          pickedFile = File(result.files.single.path!);
                          mediaType = 'image';
                          Get.back();
                          _showUpdateSheet(
                              edit: edit,
                              existingContent: textCtrl.text,
                              updateId: updateId);
                        }
                      },
                    ),
                    SizedBox(width: 8.w),
                    _MediaChip(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      onTap: () async {
                        final result =
                            await FilePicker.pickFiles(type: FileType.video);
                        if (result != null &&
                            result.files.single.path != null) {
                          pickedFile = File(result.files.single.path!);
                          mediaType = 'video';
                          Get.back();
                          _showUpdateSheet(
                              edit: edit,
                              existingContent: textCtrl.text,
                              updateId: updateId);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _statusController.isCreating.value
                            ? null
                            : () async {
                                final text = textCtrl.text.trim();
                                if (text.isEmpty && pickedFile == null) {
                                  CustomSnackbar.show(
                                      title: 'Error',
                                      message:
                                          'Please enter text or select media');
                                  return;
                                }
                                if (edit && updateId != null) {
                                  final ok = await _statusController.editUpdate(
                                      updateId, text);
                                  Get.back();
                                  if (ok) {
                                    CustomSnackbar.success(
                                        title: 'Success',
                                        message: 'Update edited');
                                  } else {
                                    CustomSnackbar.error(
                                        title: 'Failed',
                                        message: 'Could not edit update');
                                  }
                                } else {
                                  final result =
                                      await _statusController.createUpdate(
                                    text,
                                    file: pickedFile,
                                    mediaType: mediaType,
                                  );
                                  Get.back();
                                  if (result != null) {
                                    CustomSnackbar.success(
                                        title: 'Success',
                                        message: 'Update shared');
                                  } else {
                                    CustomSnackbar.error(
                                        title: 'Failed',
                                        message: 'Could not share update');
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColor.kPrimaryFill,
                          foregroundColor: CustomColor.kTextOnDark,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl.r)),
                        ),
                        child: _statusController.isCreating.value
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: CustomColor.kTextOnDark))
                            : Text(edit ? 'Save' : 'Share',
                                style: AppTextStyles.titleMd),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(String updateId) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Update',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              _statusController.deleteUpdate(updateId);
              Get.back();
              CustomSnackbar.show(title: 'Deleted', message: 'Update removed');
            },
            child:
                Text('Delete', style: TextStyle(color: CustomColor.kDangerRed)),
          ),
        ],
      ),
    );
  }

  void _showMomentsSheet() {
    final isDark = Get.isDarkMode;
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor:
          Get.isDarkMode ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
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
                )),
                SizedBox(height: 16.h),
                Text('Create Moment',
                    style: AppTextStyles.headingMd.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary)),
                SizedBox(height: 16.h),
                _MomentOption(
                  isDark: isDark,
                  icon: Icons.camera_alt_rounded,
                  label: 'Photo Moment',
                  subtitle: 'Share a photo as a moment',
                  color: CustomColor.kPrimaryColor,
                  onTap: () {
                    Get.back();
                    _createMoment('image');
                  },
                ),
                _MomentOption(
                  isDark: isDark,
                  icon: Icons.videocam_rounded,
                  label: 'Video Moment',
                  subtitle: 'Share a video as a moment',
                  color: CustomColor.kOnlineGreen,
                  onTap: () {
                    Get.back();
                    _createMoment('video');
                  },
                ),
                _MomentOption(
                  isDark: isDark,
                  icon: Icons.text_fields_rounded,
                  label: 'Text Moment',
                  subtitle: 'Share a text story with gradient background',
                  color: CustomColor.kGoldAccent,
                  onTap: () {
                    Get.back();
                    _createMoment('text');
                  },
                ),
                Divider(
                    height: 24.h,
                    color: isDark
                        ? CustomColor.kDarkDivider
                        : CustomColor.kLightBorder),
                _MomentOption(
                  isDark: isDark,
                  icon: Icons.schedule_send_rounded,
                  label: 'Schedule Moment',
                  subtitle: 'Set a date and time for automatic publishing',
                  color: CustomColor.kPrimaryColor,
                  onTap: () {
                    Get.back();
                    _scheduleMoment();
                  },
                ),
                _MomentOption(
                  isDark: isDark,
                  icon: Icons.drafts_rounded,
                  label: 'Drafts',
                  subtitle:
                      '${_momentController.draftMoments.length} saved drafts',
                  color: CustomColor.kTextSecondary,
                  onTap: () {
                    Get.back();
                    Get.to(() => const ScheduledMomentsPage(initialTab: 2));
                  },
                ),
                _MomentOption(
                  isDark: isDark,
                  icon: Icons.movie_creation_rounded,
                  label: 'Scheduled Moments',
                  subtitle:
                      '${_momentController.scheduledMoments.where((m) => m.isPending).length} pending',
                  color: CustomColor.kGoldAccent,
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: CustomColor.kTextTertiary),
                  onTap: () {
                    Get.back();
                    Get.to(() => const ScheduledMomentsPage());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createMoment(String mediaType) async {
    if (mediaType == 'text') {
      _showTextMomentSheet();
      return;
    }
    final type = mediaType == 'image' ? FileType.image : FileType.video;
    final result = await FilePicker.pickFiles(type: type);
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);

    final contentCtrl = TextEditingController();
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor:
          Get.isDarkMode ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w,
            MediaQuery.of(Get.context!).viewInsets.bottom + 20.h),
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
                    color: Get.isDarkMode
                        ? CustomColor.kDarkDivider
                        : CustomColor.kLightBorder,
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                )),
                SizedBox(height: 16.h),
                Text(
                    'Create ${mediaType == 'image' ? 'Photo' : 'Video'} Moment',
                    style: AppTextStyles.headingMd),
                SizedBox(height: 16.h),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                    filled: true,
                    fillColor: Get.isDarkMode
                        ? CustomColor.kDarkSurface2
                        : CustomColor.kUltraLightBg,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                          _showScheduleSheet(
                              contentCtrl.text.trim(), file.path, mediaType);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl.r)),
                          side: BorderSide(color: CustomColor.kPrimaryColor),
                        ),
                        child: Text('Schedule',
                            style: GoogleFonts.poppins(
                                color: CustomColor.primaryTextFor(
                                    Get.isDarkMode))),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await _statusController.createUpdate(
                            contentCtrl.text.trim(),
                            file: file,
                            mediaType: mediaType,
                          );
                          Get.back();
                          if (result != null) {
                            CustomSnackbar.success(
                                title: 'Posted',
                                message: 'Your moment is live');
                          } else {
                            CustomSnackbar.error(
                                title: 'Failed',
                                message: 'Could not post moment');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColor.kPrimaryFill,
                          foregroundColor: CustomColor.kTextOnDark,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl.r)),
                        ),
                        child: Text('Post Now',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTextMomentSheet() {
    final contentCtrl = TextEditingController();
    final colors = [
      CustomColor.kPrimaryColor,
      CustomColor.kDarkSurface,
      CustomColor.kBrandPurple,
      CustomColor.kDangerRed,
      CustomColor.kInfo,
      CustomColor.kSuccess,
    ];
    RxInt selectedColor = 0.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor:
          Get.isDarkMode ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w,
            MediaQuery.of(Get.context!).viewInsets.bottom + 20.h),
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
                    color: Get.isDarkMode
                        ? CustomColor.kDarkDivider
                        : CustomColor.kLightBorder,
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                )),
                SizedBox(height: 16.h),
                Text('Text Moment', style: AppTextStyles.headingMd),
                SizedBox(height: 12.h),
                Obx(() => AnimatedContainer(
                      duration: AppAnimation.normal,
                      width: double.infinity,
                      height: 160.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          colors[selectedColor.value],
                          colors[(selectedColor.value + 1) % colors.length]
                              .withValues(alpha: 0.7),
                        ]),
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      ),
                      padding: EdgeInsets.all(16.r),
                      child: Text(
                        contentCtrl.text.isNotEmpty
                            ? contentCtrl.text
                            : 'Your text here...',
                        style: AppTextStyles.headingMd
                            .copyWith(color: CustomColor.kTextOnDark),
                      ),
                    )),
                SizedBox(height: 12.h),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                    filled: true,
                    fillColor: Get.isDarkMode
                        ? CustomColor.kDarkSurface2
                        : CustomColor.kUltraLightBg,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: colors.map((c) {
                    final i = colors.indexOf(c);
                    return GestureDetector(
                      onTap: () => selectedColor.value = i,
                      child: Obx(() => Container(
                            width: 28.r,
                            height: 28.r,
                            margin: EdgeInsets.only(right: 8.w),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selectedColor.value == i
                                    ? CustomColor.kTextOnDark
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          )),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                          _showScheduleSheet(
                              contentCtrl.text.trim(), null, 'text');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl.r)),
                          side: BorderSide(color: CustomColor.kPrimaryColor),
                        ),
                        child: Text('Schedule',
                            style: GoogleFonts.poppins(
                                color: CustomColor.primaryTextFor(
                                    Get.isDarkMode))),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await _statusController.createUpdate(
                              contentCtrl.text.trim(),
                              mediaType: 'text');
                          Get.back();
                          if (result != null) {
                            CustomSnackbar.success(
                                title: 'Posted',
                                message: 'Text moment is live');
                          } else {
                            CustomSnackbar.error(
                                title: 'Failed',
                                message: 'Could not post text moment');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColor.kPrimaryFill,
                          foregroundColor: CustomColor.kTextOnDark,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl.r)),
                        ),
                        child: Text('Post Now',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleMoment() {
    final contentCtrl = TextEditingController();
    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor:
          Get.isDarkMode ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w,
            MediaQuery.of(Get.context!).viewInsets.bottom + 20.h),
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
                    color: Get.isDarkMode
                        ? CustomColor.kDarkDivider
                        : CustomColor.kLightBorder,
                    borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                  ),
                )),
                SizedBox(height: 16.h),
                Text('New Scheduled Moment', style: AppTextStyles.headingMd),
                SizedBox(height: 12.h),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "What's your moment?",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                    filled: true,
                    fillColor: Get.isDarkMode
                        ? CustomColor.kDarkSurface2
                        : CustomColor.kUltraLightBg,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    _MediaChip(
                      icon: Icons.image_rounded,
                      label: 'Add Image',
                      onTap: () async {
                        final result =
                            await FilePicker.pickFiles(type: FileType.image);
                        if (result != null &&
                            result.files.single.path != null) {
                          Get.back();
                          _showScheduleSheet(contentCtrl.text.trim(),
                              result.files.single.path!, 'image');
                        }
                      },
                    ),
                    SizedBox(width: 8.w),
                    _MediaChip(
                      icon: Icons.videocam_rounded,
                      label: 'Add Video',
                      onTap: () async {
                        final result =
                            await FilePicker.pickFiles(type: FileType.video);
                        if (result != null &&
                            result.files.single.path != null) {
                          Get.back();
                          _showScheduleSheet(contentCtrl.text.trim(),
                              result.files.single.path!, 'video');
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _showScheduleSheet(contentCtrl.text.trim(), null, 'text');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColor.kPrimaryFill,
                      foregroundColor: CustomColor.kTextOnDark,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                    ),
                    child: Text('Continue to Schedule',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScheduleSheet(String content, String? mediaPath, String mediaType) {
    Get.bottomSheet(
      isScrollControlled: true,
      ScheduleMomentSheet(
        content: content,
        mediaPath: mediaPath,
        mediaType: mediaType,
      ),
    );
  }

  Widget _buildMomentsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionHeader(isDark: isDark, title: 'My Moments'),
            const Spacer(),
            GestureDetector(
              onTap: _showMomentsSheet,
              child: Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded,
                    size: 18.r, color: CustomColor.kPrimaryColor),
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: () => Get.to(() => const ScheduledMomentsPage()),
              child: Text('See all',
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kPrimaryColor)),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Obx(() {
          final pending = _momentController.scheduledMoments
              .where((m) => m.isPending)
              .toList();
          final published = _momentController.publishedMoments;
          if (pending.isEmpty &&
              published.isEmpty &&
              _momentController.draftMoments.isEmpty) {
            return AppEmptyState(
              icon: Icons.movie_creation_outlined,
              title: 'No moments yet',
              message: 'Tap + to create your first moment',
              bordered: true,
            );
          }
          return Column(
            children: [
              if (_momentController.draftMoments.isNotEmpty)
                _buildQuickCard(
                    isDark,
                    Icons.drafts_rounded,
                    'Drafts',
                    '${_momentController.draftMoments.length} drafts',
                    const ScheduledMomentsPage(initialTab: 2)),
              if (pending.isNotEmpty)
                _buildQuickCard(
                    isDark,
                    Icons.schedule_rounded,
                    'Scheduled',
                    '${pending.length} moments',
                    const ScheduledMomentsPage(initialTab: 0)),
              if (published.isNotEmpty)
                ...published.take(2).map((m) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: MomentCard(moment: m),
                    )),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildQuickCard(bool isDark, IconData icon, String title,
      String subtitle, Widget destination) {
    return OpenContainer<void>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: AppAnimation.slow,
      closedElevation: 0,
      closedColor: Colors.transparent,
      openColor: isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(AppSpacing.xl.r),
          decoration: BoxDecoration(
            color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            border: Border.all(
                color: isDark
                    ? CustomColor.kDarkBorder
                    : CustomColor.kLightBorder.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                ),
                child: Icon(icon, size: 18.r, color: CustomColor.kPrimaryColor),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.bodyMd.copyWith(
                            color: isDark
                                ? CustomColor.kTextOnDark
                                : CustomColor.kTextPrimary)),
                    Text(subtitle,
                        style: AppTextStyles.caption
                            .copyWith(color: CustomColor.kTextTertiary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: CustomColor.kTextTertiary, size: 18.r),
            ],
          ),
        ),
      ),
      openBuilder: (context, _) => destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: CustomColor.kPrimaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                SizedBox(height: 20.h),
                Obx(() {
                  if (_statusController.isLoading.value &&
                      _statusController.myUpdate.value == null) {
                    return _StatusCardSkeleton(isDark: isDark);
                  }
                  return _buildMyStatusCard(isDark);
                }),
                SizedBox(height: 24.h),
                _buildSectionTitle(isDark, 'Updates from contacts'),
                SizedBox(height: 12.h),
                Obx(() => _buildStatusStories(isDark)),
                SizedBox(height: 28.h),
                Obx(() => _AvailabilitySection(
                      isDark: isDark,
                      availabilities: _availabilities,
                      selected: _statusController.availability.value,
                      onSelected: (v) =>
                          _statusController.changeAvailability(v),
                    )),
                SizedBox(height: 28.h),
                _TodayScheduleSection(
                    isDark: isDark, birdController: _birdController),
                SizedBox(height: 28.h),
                _buildMomentsSection(isDark),
                SizedBox(height: 28.h),
                Obx(() => _ArchiveSection(
                      isDark: isDark,
                      expanded: _showArchived,
                      count: _statusController.archivedUpdates.length,
                      archivedUpdates: _statusController.archivedUpdates,
                      onToggle: () =>
                          setState(() => _showArchived = !_showArchived),
                      onRestore: (id) =>
                          _statusController.archiveUpdate(id, false),
                      onDelete: (id) => _statusController.deleteUpdate(id),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: BoxDecoration(
            gradient: CustomColor.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
          ),
          child: Icon(Icons.wifi_tethering_rounded,
              color: CustomColor.kTextOnDark, size: 20.r),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'Status',
            style: AppTextStyles.displayMedium.copyWith(
                color:
                    isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
                letterSpacing: -0.5),
          ),
        ),
        _headerAction(Icons.camera_alt_outlined, 'Add a photo or video status',
            _showCreateSheet),
        SizedBox(width: 8.w),
        _headerAction(
            Icons.create_rounded, 'Write a status', () => _showUpdateSheet()),
      ],
    );
  }

  Widget _headerAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18.r, color: CustomColor.kPrimaryColor),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Text(
      title,
      style: AppTextStyles.headingSm.copyWith(
          color: isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary),
    );
  }

  Widget _buildMyStatusCard(bool isDark) {
    final user = _userController.user;
    final image = user?.userImage ?? '';
    final latest = _statusController.myUpdate.value?.latestUpdate;
    final hasUpdate = latest != null;

    return GestureDetector(
      onTap: _openMyStatuses,
      onLongPress: hasUpdate ? () => _showMyStatusActions(latest) : null,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          border: Border.all(
            color: isDark
                ? CustomColor.kDarkBorder
                : CustomColor.kLightBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            _ringAvatar(
              image: image,
              size: 54.r,
              isDark: isDark,
              ringColor: hasUpdate
                  ? CustomColor.kPrimaryColor
                  : CustomColor.kOnlineGreen,
              showPlus: !hasUpdate,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMd.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    hasUpdate
                        ? (latest.replyCount != null && latest.replyCount! > 0)
                            ? '${_timeText(latest.suCreatedAt)} · ${latest.replyCount} replies'
                            : '${_timeText(latest.suCreatedAt)} · ${latest.viewCount ?? 0} views'
                        : 'Tap to add a status',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDarkMuted
                            : CustomColor.kTextTertiary),
                  ),
                ],
              ),
            ),
            if (hasUpdate)
              GestureDetector(
                onTap: () => Get.to(() => StatusViewersScreen(status: latest)),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded,
                          size: 14.r, color: CustomColor.kPrimaryColor),
                      SizedBox(width: 4.w),
                      Text(
                        '${latest.viewCount ?? 0}',
                        style: AppTextStyles.bodySm
                            .copyWith(color: CustomColor.kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(width: 8.w),
            Icon(Icons.chevron_right_rounded,
                size: 18.r, color: CustomColor.kTextTertiary),
          ],
        ),
      ),
    );
  }

  Widget _ringAvatar({
    required String image,
    required double size,
    required bool isDark,
    required Color ringColor,
    bool showPlus = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(2.5.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [ringColor, CustomColor.kPrimaryMedium],
            ),
          ),
          child: CircleAvatar(
            backgroundColor:
                isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
            backgroundImage: image.isNotEmpty
                ? NetworkImage('${Endpoints.mediaBaseUrl}$image')
                : null,
            onBackgroundImageError: image.isNotEmpty ? (_, __) {} : null,
            child: image.isEmpty
                ? Icon(Icons.person_rounded,
                    size: size * 0.45, color: CustomColor.kPrimaryColor)
                : null,
          ),
        ),
        if (showPlus)
          Positioned(
            right: -2.r,
            bottom: -2.r,
            child: Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CustomColor.kOnlineGreen,
                border: Border.all(
                  color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
                  width: 2,
                ),
              ),
              child: Icon(Icons.add_rounded,
                  size: 12.r, color: CustomColor.kTextOnDark),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusStories(bool isDark) {
    // Scheduled moments lead the row (soonest first) with their own design,
    // before friends' live stories.
    final pending = _momentController.scheduledMoments
        .where((m) => m.isPending)
        .toList()
      ..sort(
          (a, b) => (a.scheduledEpoch ?? 0).compareTo(b.scheduledEpoch ?? 0));
    final grouped = <String, List<FriendUpdate>>{};
    for (final u in _statusController.friendUpdates) {
      if (u.update == null || u.update!.isExpired) continue;
      final authorId = u.author?['user_id']?.toString() ?? 'unknown';
      grouped.putIfAbsent(authorId, () => []).add(u);
    }
    final groups = grouped.values.toList();

    if (_statusController.isLoading.value &&
        groups.isEmpty &&
        pending.isEmpty) {
      return _StoryRowSkeleton(isDark: isDark);
    }
    if (groups.isEmpty && pending.isEmpty) {
      AppEmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No status updates yet',
        message: 'Statuses from your contacts will appear here',
        bordered: true,
      );
    }
    return SizedBox(
      height: 208.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pending.length + groups.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          if (index < pending.length) {
            return Entrance(
              delayFactor: (index % 8) * 0.05,
              slideOffset: const Offset(0, 24),
              child: _buildScheduledStoryCard(isDark, pending[index]),
            );
          }
          final group = groups[index - pending.length];
          return Entrance(
            delayFactor: ((index - pending.length) % 8) * 0.05,
            slideOffset: const Offset(0, 24),
            child: _buildStoryCard(isDark, group, groups),
          );
        },
      ),
    );
  }

  /// Distinct card for a pending (scheduled) moment in the top stories row:
  /// gold-accented frame, "Scheduled" badge, publish time and live countdown.
  Widget _buildScheduledStoryCard(bool isDark, ScheduledMoment moment) {
    final mediaUrl = moment.smMediaUrl ?? '';
    final hasMedia = mediaUrl.isNotEmpty && moment.smMediaType != 'text';
    final caption = (moment.smCaption?.trim().isNotEmpty ?? false)
        ? moment.smCaption!
        : (hasMedia
            ? (moment.smMediaType == 'video' ? 'Video moment' : 'Photo moment')
            : 'Text moment');

    return OpenContainer<void>(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: AppAnimation.slow,
      closedElevation: 0,
      closedColor: Colors.transparent,
      openColor: isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        child: Container(
          width: 138.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            border: Border.all(
              color: CustomColor.kGoldAccent.withValues(alpha: 0.55),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kGoldAccent.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasMedia)
                CachedNetworkImage(
                  imageUrl: '${Endpoints.mediaBaseUrl}$mediaUrl',
                  fit: BoxFit.cover,
                  color: CustomColor.kScrim45,
                  colorBlendMode: BlendMode.darken,
                  placeholder: (_, __) => _scheduledCardBackground(),
                  errorWidget: (_, __, ___) => _scheduledCardBackground(),
                )
              else
                _scheduledCardBackground(),
              if (!hasMedia)
                Positioned(
                  left: 12.r,
                  right: 12.r,
                  top: 48.h,
                  child: Text(
                    caption,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm
                        .copyWith(color: CustomColor.kTextOnDark),
                  ),
                ),
              Positioned(
                top: 8.r,
                left: 8.r,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: CustomColor.kScrim45,
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 10.r, color: CustomColor.kGoldAccent),
                      SizedBox(width: 4.w),
                      Text(
                        'Scheduled',
                        style: AppTextStyles.labelSm
                            .copyWith(color: CustomColor.kTextOnDark),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10.w,
                right: 10.w,
                bottom: 10.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _scheduledTimeLabel(moment),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: CustomColor.kTextOnDark),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Icon(Icons.timelapse_rounded,
                            size: 11.r, color: CustomColor.kGoldAccent),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            _countdownLabel(moment),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSm
                                .copyWith(color: CustomColor.kOverlay70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      openBuilder: (context, _) => const ScheduledMomentsPage(initialTab: 0),
    );
  }

  Widget _scheduledCardBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CustomColor.kWarningDeep, CustomColor.kWarningDeep],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: CustomColor.kTextOnDark.withValues(alpha: 0.18),
          size: 40.r,
        ),
      ),
    );
  }

  String _scheduledTimeLabel(ScheduledMoment moment) {
    final epoch = moment.scheduledEpoch;
    if (epoch == null) return 'Unscheduled';
    final dt = DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    return DateFormat('EEE, MMM d · hh:mm a').format(dt);
  }

  String _countdownLabel(ScheduledMoment moment) {
    final epoch = moment.scheduledEpoch;
    if (epoch == null) return 'Waiting for publish time';
    final diff = DateTime.fromMillisecondsSinceEpoch(epoch * 1000)
        .difference(DateTime.now());
    if (diff.inSeconds <= 60) return 'Publishing…';
    if (diff.inDays >= 1)
      return 'in ${diff.inDays}d ${diff.inHours.remainder(24)}h';
    if (diff.inHours >= 1)
      return 'in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    return 'in ${diff.inMinutes}m';
  }

  Widget _buildStoryCard(bool isDark, List<FriendUpdate> group,
      List<List<FriendUpdate>> allGroups) {
    final update = group.first;
    final status = update.update!;
    final author = update.author;
    final authorId = author?['user_id']?.toString() ?? '';
    final storyCount = group.length;
    var name =
        authorId.isNotEmpty ? _contactController.getUserNameById(authorId) : '';
    if (name.isEmpty) {
      name = author != null
          ? '${author['user_first_name'] ?? ''} ${author['user_last_name'] ?? ''}'
              .trim()
          : '';
    }
    if (name.isEmpty) name = 'User';
    final image = author?['user_image']?.toString() ?? '';
    final mediaUrl = status.suMediaUrl ?? '';
    final mediaType = status.suMediaType ?? 'text';
    final hasMedia =
        mediaUrl.isNotEmpty && (mediaType == 'image' || mediaType == 'video');
    final viewed = group.every((f) => f.viewed == true);
    // WhatsApp-style: statuses the user already replied to / reacted on stay
    // highlighted with a reply badge, even after they've been viewed.
    final interacted = group.any((f) => f.hasInteracted);

    return GestureDetector(
      onTap: () => Get.to(() => StatusViewerScreen(
            updates: group,
            // Resume from the first story this user hasn't seen yet.
            initialIndex: group
                .indexWhere((f) => f.viewed != true)
                .clamp(0, group.length - 1),
            // Flow into the next/previous contact's stories at the group edges.
            allGroups: allGroups,
            initialGroupIndex: allGroups.indexOf(group),
          )),
      child: Container(
        width: 138.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
            color: isDark
                ? CustomColor.kDarkBorder
                : CustomColor.kTextOnDark.withValues(alpha: 0.7),
          ),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kScrim20,
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (storyCount > 1)
              Positioned(
                top: 8.r,
                left: 8.r,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: CustomColor.kScrim45,
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 10.r, color: CustomColor.kTextOnDark),
                      SizedBox(width: 4.w),
                      Text(
                        '$storyCount',
                        style: AppTextStyles.labelSm
                            .copyWith(color: CustomColor.kTextOnDark),
                      ),
                    ],
                  ),
                ),
              ),
            if (hasMedia)
              CachedNetworkImage(
                imageUrl: '${Endpoints.mediaBaseUrl}$mediaUrl',
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: CustomColor.primaryGradient,
                  ),
                ),
                errorWidget: (_, __, ___) =>
                    _storyTextBackground(status, isDark),
              )
            else
              _storyTextBackground(status, isDark),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 96.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: viewed ? 0.55 : 0.78),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10.w,
              right: 10.w,
              bottom: 10.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _storyAvatar(
                          image: image,
                          isDark: isDark,
                          viewed: viewed,
                          interacted: interacted),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm
                                  .copyWith(color: CustomColor.kTextOnDark),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _timeText(status.suCreatedAt),
                              style: AppTextStyles.labelSm
                                  .copyWith(color: CustomColor.kOverlay70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (viewed && !interacted)
              Positioned(
                top: 8.r,
                right: 8.r,
                child: Container(
                  width: 22.r,
                  height: 22.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kScrim45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      size: 13.r, color: CustomColor.kTextOnDark),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _storyTextBackground(StatusModel status, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomColor.kPrimaryColor,
            CustomColor.kPrimaryMedium,
          ],
        ),
      ),
      padding: EdgeInsets.all(12.r),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status.suMediaType == 'voice'
                ? Icons.mic_rounded
                : Icons.text_fields_rounded,
            color: CustomColor.kOverlay70,
            size: 20.r,
          ),
          SizedBox(height: 6.h),
          Text(
            (status.suContent?.isNotEmpty ?? false)
                ? status.suContent!
                : 'New status',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodySm.copyWith(color: CustomColor.kTextOnDark),
          ),
        ],
      ),
    );
  }

  Widget _storyAvatar(
      {required String image,
      required bool isDark,
      required bool viewed,
      bool interacted = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 34.r,
          height: 34.r,
          padding: EdgeInsets.all(2.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: viewed ? null : CustomColor.primaryGradient,
            color: viewed ? CustomColor.kOverlay38 : null,
          ),
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            backgroundImage: image.isNotEmpty
                ? NetworkImage('${Endpoints.mediaBaseUrl}$image')
                : null,
            onBackgroundImageError: image.isNotEmpty ? (_, __) {} : null,
            child: image.isEmpty
                ? Icon(Icons.person_rounded,
                    size: 16.r, color: CustomColor.kTextOnDark)
                : null,
          ),
        ),
        if (interacted)
          Positioned(
            right: -4.r,
            bottom: -4.r,
            child: Container(
              width: 18.r,
              height: 18.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CustomColor.kPrimaryColor,
                border: Border.all(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.reply_rounded,
                  size: 10.r, color: CustomColor.kTextOnDark),
            ),
          ),
      ],
    );
  }

  String _timeText(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    final dt = AppHelper.parseServerUtc(createdAt);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _MediaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MediaChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.r, color: CustomColor.kPrimaryColor),
            SizedBox(width: 6.w),
            Text(label,
                style: AppTextStyles.bodySm
                    .copyWith(color: CustomColor.kPrimaryColor)),
          ],
        ),
      ),
    );
  }
}

class _StatusCardSkeleton extends StatelessWidget {
  final bool isDark;
  const _StatusCardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78.h,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(
          color: isDark
              ? CustomColor.kDarkBorder
              : CustomColor.kLightBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
              color: isDark
                  ? CustomColor.kDarkSurface2
                  : CustomColor.kUltraLightBg,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 14.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 110.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? CustomColor.kDarkSurface2
                      : CustomColor.kUltraLightBg,
                  borderRadius: BorderRadius.circular(AppRadius.xs.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 80.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? CustomColor.kDarkSurface2
                      : CustomColor.kUltraLightBg,
                  borderRadius: BorderRadius.circular(AppRadius.xs.r),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryRowSkeleton extends StatelessWidget {
  final bool isDark;
  const _StoryRowSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, __) => Container(
          width: 138.w,
          decoration: BoxDecoration(
            color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            border: Border.all(
              color: isDark
                  ? CustomColor.kDarkBorder
                  : CustomColor.kLightBorder.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilitySection extends StatelessWidget {
  final bool isDark;
  final List<String> availabilities;
  final String selected;
  final ValueChanged<String> onSelected;

  const _AvailabilitySection({
    required this.isDark,
    required this.availabilities,
    required this.selected,
    required this.onSelected,
  });

  static const _colors = {
    'Available': CustomColor.kOnlineGreen,
    'Busy': CustomColor.kDangerRed,
    'In Meeting': CustomColor.kGoldAccent,
    'Focus Mode': CustomColor.kPrimaryColor,
    'Travelling': CustomColor.kBrandPurple,
    'Offline': CustomColor.kTextTertiary,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(isDark: isDark, title: 'Availability'),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: availabilities.map((a) {
            final sel = selected == a;
            final color = _colors[a] ?? CustomColor.kPrimaryColor;
            return GestureDetector(
              onTap: () => onSelected(a),
              child: AnimatedContainer(
                duration: AppAnimation.normal,
                curve: Curves.easeOutCubic,
                height: 40.h,
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                decoration: BoxDecoration(
                  color:
                      sel ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  border: Border.all(
                    color: sel
                        ? color
                        : (isDark
                            ? CustomColor.kDarkDivider
                            : CustomColor.kLightBorder),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        color: sel
                            ? color
                            : (isDark
                                ? CustomColor.kTextOnDarkMuted
                                : CustomColor.kTextTertiary),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(a,
                        style: AppTextStyles.label.copyWith(
                            color: sel
                                ? (isDark ? CustomColor.kTextOnDark : color)
                                : (isDark
                                    ? CustomColor.kTextOnDarkMuted
                                    : CustomColor.kTextSecondary))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MomentOption extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MomentOption({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44.r,
        height: 44.r,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
        child: Icon(icon, color: color, size: 22.r),
      ),
      title: Text(label,
          style: AppTextStyles.bodyMd.copyWith(
              color:
                  isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary)),
      subtitle: Text(subtitle,
          style:
              AppTextStyles.caption.copyWith(color: CustomColor.kTextTertiary)),
      trailing: trailing ??
          Container(
            width: 24.r,
            height: 24.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_rounded, color: color, size: 16.r),
          ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _TodayScheduleSection extends StatelessWidget {
  final bool isDark;
  final BirdController? birdController;

  const _TodayScheduleSection({required this.isDark, this.birdController});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hasSchedule = birdController != null &&
        birdController!.scheduledMessagesMap.containsKey(today) &&
        birdController!.scheduledMessagesMap[today]!.isNotEmpty;
    final count =
        hasSchedule ? birdController!.scheduledMessagesMap[today]!.length : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
            isDark: isDark,
            title: "Today's Schedule",
            trailing: hasSchedule ? '$count scheduled' : null),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.xxl.r),
          decoration: BoxDecoration(
            color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(
              color: isDark
                  ? CustomColor.kDarkBorder
                  : CustomColor.kLightBorder.withValues(alpha: 0.5),
            ),
          ),
          child: hasSchedule
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: birdController!.scheduledMessagesMap[today]!
                      .take(3)
                      .map((msg) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_send_rounded,
                              size: 16.r, color: CustomColor.kGoldAccent),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              msg.mMessage ?? 'Scheduled message',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.subtitle.copyWith(
                                  color: isDark
                                      ? CustomColor.kTextOnDarkSecondary
                                      : CustomColor.kTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Row(
                  children: [
                    Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      ),
                      child: Icon(Icons.schedule_rounded,
                          size: 18.r, color: CustomColor.kPrimaryColor),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text('No schedules for today',
                          style: AppTextStyles.bodyMd.copyWith(
                              color: isDark
                                  ? CustomColor.kTextOnDarkMuted
                                  : CustomColor.kTextTertiary)),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ArchiveSection extends StatelessWidget {
  final bool isDark;
  final bool expanded;
  final int count;
  final List<StatusModel> archivedUpdates;
  final VoidCallback onToggle;
  final ValueChanged<String> onRestore;
  final ValueChanged<String> onDelete;

  const _ArchiveSection({
    required this.isDark,
    required this.expanded,
    required this.count,
    required this.archivedUpdates,
    required this.onToggle,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(isDark: isDark, title: 'Archive'),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: AppAnimation.normal,
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.xxl.r),
            decoration: BoxDecoration(
              color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
              borderRadius: BorderRadius.circular(AppRadius.xxl.r),
              border: Border.all(
                color: isDark
                    ? CustomColor.kDarkBorder
                    : CustomColor.kLightBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kTextTertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(Icons.archive_rounded,
                      size: 18.r, color: CustomColor.kTextTertiary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text('Archived Updates',
                      style: AppTextStyles.bodyMd.copyWith(
                          color: isDark
                              ? CustomColor.kTextOnDark
                              : CustomColor.kTextPrimary)),
                ),
                Text(count.toString(),
                    style: AppTextStyles.bodySm.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDarkMuted
                            : CustomColor.kTextTertiary)),
                SizedBox(width: 8.w),
                AnimatedRotation(
                  duration: AppAnimation.normal,
                  turns: expanded ? 0.25 : 0,
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 12.r,
                      color: isDark
                          ? CustomColor.kTextOnDarkMuted
                          : CustomColor.kTextTertiary),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: archivedUpdates.isEmpty
                ? AppEmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'Archive is empty',
                    message: 'Expired updates appear here',
                    bordered: true,
                  )
                : Column(
                    children: archivedUpdates
                        .map((u) => Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(AppSpacing.xl.r),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? CustomColor.kDarkSurface
                                    : CustomColor.kWhite,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl.r),
                                border: Border.all(
                                    color: isDark
                                        ? CustomColor.kDarkBorder
                                        : CustomColor.kLightBorder
                                            .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(u.suContent ?? 'Media update',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.subtitle),
                                        if (u.suCreatedAt != null)
                                          SizedBox(height: 2.h),
                                        if (u.suCreatedAt != null)
                                          Text(
                                            DateFormat('MMM d, yyyy').format(
                                                AppHelper.parseServerUtc(
                                                        u.suCreatedAt!) ??
                                                    DateTime.now()),
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color: CustomColor
                                                        .kTextTertiary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.restore_rounded,
                                        size: 18.r,
                                        color: CustomColor.kPrimaryColor),
                                    onPressed: u.suId != null
                                        ? () => onRestore(u.suId!)
                                        : null,
                                    tooltip: 'Restore',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        size: 18.r,
                                        color: CustomColor.kDangerRed),
                                    onPressed: u.suId != null
                                        ? () => onDelete(u.suId!)
                                        : null,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final bool isDark;
  final String title;
  final String? trailing;

  const _SectionHeader(
      {required this.isDark, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 3.w,
            height: 16.h,
            decoration: BoxDecoration(
              gradient: CustomColor.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xxs.r),
            )),
        SizedBox(width: 8.w),
        Text(title,
            style: AppTextStyles.headingSm.copyWith(
                color: isDark
                    ? CustomColor.kTextOnDark
                    : CustomColor.kTextPrimary)),
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing!,
              style: AppTextStyles.error
                  .copyWith(color: CustomColor.kPrimaryColor)),
        ],
      ],
    );
  }
}
