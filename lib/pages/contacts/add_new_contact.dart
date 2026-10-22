import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/common_textfield.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class AddContact extends StatefulWidget {
  const AddContact({super.key});

  @override
  State<AddContact> createState() => _AddContactState();
}

class _AddContactState extends State<AddContact> {
  ContactController contactController = Get.find();
  UserController userController = Get.find();
  ChatController chatController = Get.find();
  File? _profileImage;
  String _countryCode = '+91';
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    contactController.firstNameController = TextEditingController();
    contactController.lastNameController = TextEditingController();
    contactController.numberController = TextEditingController();
    contactController.emailController = TextEditingController();
    contactController.companyController = TextEditingController();
    contactController.notesController = TextEditingController();

    if (Get.arguments?['name'] != null) {
      List<String> name = Get.arguments['name'].toString().split(' ');
      contactController.firstNameController.text = name[0];
      contactController.lastNameController.text = name.sublist(1).join(' ');
      contactController.numberController.text = Get.arguments['number'];
    }
  }

  @override
  void dispose() {
    contactController.firstNameController.dispose();
    contactController.lastNameController.dispose();
    contactController.numberController.dispose();
    contactController.emailController.dispose();
    contactController.companyController.dispose();
    contactController.notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        useSafeArea: true,
        builder: (_) => SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Profile Photo', style: AppTextStyles.headingSm),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ImageOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () => Get.back(result: ImageSource.camera),
                    ),
                    _ImageOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => Get.back(result: ImageSource.gallery),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      );
      if (source == null) return;
      final picked = await _picker.pickImage(source: source, maxWidth: 512);
      if (picked != null && mounted)
        setState(() => _profileImage = File(picked.path));
    } catch (_) {}
  }

  void _startChat(User user) async {
    try {
      if (!mounted) return;
      final (exists, room) = contactController.checkIfRoomExists(user);
      if (exists && room != null) {
        Get.to(() => ChatScreen(
              name: '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                  .trim(),
              userNumber: user.userMobileNum ?? '',
              roomId: room.rId ?? '',
              receiverId: user.userId ?? '',
              isGroup: false,
              userProfile: user.userImage ?? '',
            ));
        return;
      }
      final userNumber = userController.user?.userMobileNum ?? '';
      final RoomsModel? result = await RoomApi().createRoom(
        0,
        '',
        [userNumber, user.userMobileNum ?? ''],
      );
      if (result?.status ?? false) {
        final newRoom = result!.room!;
        contactController.homeController.singleChatsList.insert(0, newRoom);
        contactController.homeController.update(['update-card']);
        Get.to(() => ChatScreen(
              name: '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                  .trim(),
              userNumber: user.userMobileNum ?? '',
              roomId: newRoom.rId ?? '',
              receiverId: user.userId ?? '',
              isGroup: false,
              userProfile: user.userImage ?? '',
            ));
      } else {
        Utils.showGetSnackBar('Could not create chat');
      }
    } catch (e) {
      Utils.showGetSnackBar('Failed to start chat. Please try again.');
    }
  }

  Future<void> _openSchedule(User user) async {
    try {
      final (exists, room) = contactController.checkIfRoomExists(user);
      if (room != null) {
        Get.to(() => ScheduleScreen(
              name: '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                  .trim(),
              roomId: room.rId ?? '',
              receiverId: user.userId ?? '',
              roomUsers: room.rUsers ?? '',
            ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Add Contact',
        showBackButton: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20.w,
          16.h,
          20.w,
          16.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Obx(() {
          if (contactController.isPageReady.isFalse) {
            return Center(
              child: Text("Page not found",
                  style: AppTextStyles.bodyMd
                      .copyWith(color: CustomColor.kTextSecondary)),
            );
          }
          return Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 44.r,
                      backgroundColor: CustomColor.kPrimaryLight,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      onBackgroundImageError:
                          _profileImage != null ? (_, __) {} : null,
                      child: _profileImage == null
                          ? Icon(Icons.person_rounded,
                              size: 40.r, color: CustomColor.kPrimaryColor)
                          : null,
                    ),
                    Positioned(
                      bottom: 0.h,
                      right: 0.w,
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: CustomColor.kPrimaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: CustomColor.kTextOnDark, width: 2),
                        ),
                        child: Icon(Icons.camera_alt_rounded,
                            size: 16.r, color: CustomColor.kTextOnDark),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: CustomColor.kLightSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
                  boxShadow: AppShadow.cardLight,
                ),
                child: Column(
                  children: [
                    CommonTextField(
                      controller: contactController.firstNameController,
                      hintText: 'First Name *',
                      bgColor: CustomColor.kUltraLightPrimary,
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    CommonTextField(
                      controller: contactController.lastNameController,
                      hintText: 'Last Name',
                      bgColor: CustomColor.kUltraLightPrimary,
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: CustomColor.kUltraLightPrimary,
                            borderRadius:
                                BorderRadius.circular(AppRadius.xxl.r),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _countryCode,
                              dropdownColor: CustomColor.kLightSurface,
                              style: AppTextStyles.bodyMd,
                              items: const [
                                DropdownMenuItem(
                                    value: '+1', child: Text('🇺🇸 +1')),
                                DropdownMenuItem(
                                    value: '+44', child: Text('🇬🇧 +44')),
                                DropdownMenuItem(
                                    value: '+91', child: Text('🇮🇳 +91')),
                                DropdownMenuItem(
                                    value: '+61', child: Text('🇦🇺 +61')),
                                DropdownMenuItem(
                                    value: '+81', child: Text('🇯🇵 +81')),
                                DropdownMenuItem(
                                    value: '+86', child: Text('🇨🇳 +86')),
                                DropdownMenuItem(
                                    value: '+49', child: Text('🇩🇪 +49')),
                                DropdownMenuItem(
                                    value: '+33', child: Text('🇫🇷 +33')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _countryCode = v);
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: CommonTextField(
                            controller: contactController.numberController,
                            hintText: 'Mobile Number *',
                            bgColor: CustomColor.kUltraLightPrimary,
                            onChanged: (val) {
                              contactController
                                  .checkUserExists('$_countryCode$val');
                            },
                          ),
                        ),
                      ],
                    ),
                    if (contactController.checkedUserStatus.value == 'checking')
                      Padding(
                        padding: EdgeInsets.only(top: 12.h),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14.r,
                              height: 14.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CustomColor.kPrimaryColor,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text('Checking...',
                                style: AppTextStyles.bodySm.copyWith(
                                    color: CustomColor.kTextTertiary)),
                          ],
                        ),
                      ),
                    if (contactController.checkedUserStatus.value == 'found' &&
                        contactController.checkedUser.value != null)
                      _buildUserFound(contactController.checkedUser.value!),
                    if (contactController.checkedUserStatus.value ==
                        'not_found')
                      _buildUserNotFound(),
                    SizedBox(height: AppSpacing.xxl.h),
                    CommonTextField(
                      controller: contactController.emailController,
                      hintText: 'Email',
                      bgColor: CustomColor.kUltraLightPrimary,
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    CommonTextField(
                      controller: contactController.companyController,
                      hintText: 'Company',
                      bgColor: CustomColor.kUltraLightPrimary,
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    CommonTextField(
                      controller: contactController.notesController,
                      hintText: 'Notes',
                      bgColor: CustomColor.kUltraLightPrimary,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xsection.h),
              Obx(() => contactController.isAddingContact.isFalse
                  ? AppButton(
                      text: 'Save Contact',
                      onTap: () => contactController.saveNewContact(),
                      buttonSize: Size(Get.width * 0.5, 48.h),
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            CustomColor.kPrimaryColor),
                      ),
                    )),
              SizedBox(height: 40.h),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildUserFound(User user) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: CustomColor.kSuccess.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(color: CustomColor.kSuccess.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: CustomColor.kPrimaryLight,
                backgroundImage: (user.userImage ?? '').isNotEmpty
                    ? CachedNetworkImageProvider(
                        '${Endpoints.mediaBaseUrl}${user.userImage}')
                    : null,
                onBackgroundImageError:
                    (user.userImage ?? '').isNotEmpty ? (_, __) {} : null,
                child: (user.userImage ?? '').isEmpty
                    ? Icon(Icons.person_rounded,
                        size: 22.r, color: CustomColor.kPrimaryColor)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                                .trim(),
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.verified_rounded,
                            size: 14.r, color: CustomColor.kPrimaryColor),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'On Humming Bird',
                      style: AppTextStyles.helper.copyWith(
                          color: CustomColor.kSuccess,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _ActionChip(
                icon: Icons.chat_rounded,
                label: 'Chat',
                onTap: () => _startChat(user),
              ),
              SizedBox(width: 8.w),
              _ActionChip(
                icon: Icons.phone_rounded,
                label: 'Call',
                onTap: () {
                  final number = user.userMobileNum ?? '';
                  if (number.isNotEmpty) {
                    launchUrl(Uri.parse('tel:$number'));
                  }
                },
              ),
              SizedBox(width: 8.w),
              _ActionChip(
                icon: Icons.schedule_send_rounded,
                label: 'Schedule',
                onTap: () => _openSchedule(user),
              ),
              SizedBox(width: 8.w),
              _ActionChip(
                icon: Icons.group_add_rounded,
                label: 'Group',
                onTap: () => contactController
                    .sendInviteMessage(user.userMobileNum ?? ''),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserNotFound() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: CustomColor.kTextTertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(
            color: CustomColor.kTextTertiary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_off_rounded,
              size: 28.r, color: CustomColor.kTextTertiary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Not on Humming Bird',
                    style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CustomColor.kTextSecondary)),
                SizedBox(height: 2.h),
                Text('Invite them to join',
                    style: AppTextStyles.helper
                        .copyWith(color: CustomColor.kTextTertiary)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: CustomColor.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl.r),
            ),
            child: TextButton.icon(
              onPressed: () => contactController.sendInviteMessage(
                  contactController.numberController.text.trim()),
              style: TextButton.styleFrom(
                foregroundColor: CustomColor.kTextOnDark,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl.r)),
              ),
              icon: Icon(Icons.send_rounded, size: 16.r),
              label: Text('Invite',
                  style: AppTextStyles.bodySm
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: CustomColor.kUltraLightPrimary,
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          border: Border.all(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32.r, color: CustomColor.kPrimaryColor),
            SizedBox(height: 8.h),
            Text(label, style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18.r, color: CustomColor.kPrimaryColor),
              SizedBox(height: 2.h),
              Text(label,
                  style: AppTextStyles.helper.copyWith(
                      color: CustomColor.kPrimaryColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
