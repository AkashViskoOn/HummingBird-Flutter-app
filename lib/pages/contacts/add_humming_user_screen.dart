import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_screen.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AddHummingBirdUserScreen extends StatefulWidget {
  const AddHummingBirdUserScreen({super.key});

  @override
  State<AddHummingBirdUserScreen> createState() =>
      _AddHummingBirdUserScreenState();
}

class _AddHummingBirdUserScreenState extends State<AddHummingBirdUserScreen> {
  final ContactController contactController = Get.find();
  final UserController userController = Get.find();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryCodeController =
      TextEditingController(text: '+91');

  bool _loading = false;
  User? _foundUser;
  bool _notFound = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _countryCodeController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) return;

    setState(() {
      _loading = true;
      _foundUser = null;
      _notFound = false;
      _error = null;
    });

    try {
      final number =
          '${_countryCodeController.text.replaceAll(RegExp(r'\D'), '')}${raw.replaceAll(RegExp(r'\D'), '')}';
      final user = await contactController.searchUserByPhone(number);
      if (!mounted) return;
      if (user != null) {
        setState(() {
          _foundUser = user;
          _notFound = false;
        });
      } else {
        setState(() {
          _foundUser = null;
          _notFound = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChat(User user) async {
    final existing = contactController.checkIfRoomExists(user);
    if (existing.$1 && existing.$2?.rId != null) {
      Get.to(() => ChatScreen(
            name:
                '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'.trim(),
            userNumber: user.userMobileNum ?? '',
            roomId: existing.$2!.rId!,
            userProfile: user.userImage ?? '',
            receiverId: user.userId ?? '',
          ));
    } else {
      final userNumber = userController.user?.userMobileNum ?? '';
      final result = await RoomApi().createRoom(
        0,
        '',
        [userNumber, user.userMobileNum ?? ''],
      );
      if (result?.status == true && result!.room != null) {
        final newRoom = result.room!;
        contactController.homeController.singleChatsList.insert(0, newRoom);
        contactController.homeController.update(['update-card']);
        Get.to(() => ChatScreen(
              name: '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                  .trim(),
              userNumber: user.userMobileNum ?? '',
              roomId: newRoom.rId!,
              userProfile: user.userImage ?? '',
              receiverId: user.userId ?? '',
            ));
      } else {
        Utils.showGetSnackBar('Could not create chat');
      }
    }
  }

  void _addContact(User user) {
    contactController.addHummingContact(user);
    Get.back();
    CustomSnackbar.success(
        title: 'Contact Added',
        message:
            '${user.userFirstName ?? ''} has been added to your contacts.');
  }

  Future<void> _openSchedule(User user) async {
    final existing = contactController.checkIfRoomExists(user);
    if (existing.$1 && existing.$2?.rId != null) {
      Get.to(() => ScheduleScreen(
            name:
                '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'.trim(),
            roomId: existing.$2!.rId!,
            receiverId: user.userId ?? '',
            roomUsers: '',
          ));
    } else {
      final userNumber = userController.user?.userMobileNum ?? '';
      final result = await RoomApi().createRoom(
        0,
        '',
        [userNumber, user.userMobileNum ?? ''],
      );
      if (result?.status == true && result!.room != null) {
        final newRoom = result.room!;
        contactController.homeController.singleChatsList.insert(0, newRoom);
        contactController.homeController.update(['update-card']);
        Get.to(() => ScheduleScreen(
              name: '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                  .trim(),
              roomId: newRoom.rId!,
              receiverId: user.userId ?? '',
              roomUsers: '',
            ));
      } else {
        Utils.showGetSnackBar('Could not create chat');
      }
    }
  }

  void _inviteUser() {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) return;
    final number =
        '${_countryCodeController.text.replaceAll(RegExp(r'\D'), '')}${raw.replaceAll(RegExp(r'\D'), '')}';
    contactController.sendInviteMessage(number);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kUltraLightPrimary,
      appBar: CommonAppBar(title: 'Add Humming Bird User'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20.r, 20.r, 20.r, 20.r + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Search by phone number',
              style:
                  (isDark ? AppTextStyles.bodySmOnDark : AppTextStyles.bodySm)
                      .copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                SizedBox(
                  width: 80.w,
                  child: TextField(
                    controller: _countryCodeController,
                    keyboardType: TextInputType.phone,
                    style: (isDark
                            ? AppTextStyles.bodyMdOnDark
                            : AppTextStyles.bodyMd)
                        .copyWith(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 14.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                        borderSide: BorderSide(
                            color: isDark
                                ? CustomColor.kDarkBorder
                                : CustomColor.kLightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                        borderSide: BorderSide(
                            color: isDark
                                ? CustomColor.kDarkBorder
                                : CustomColor.kLightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                        borderSide:
                            const BorderSide(color: CustomColor.kPrimaryColor),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? CustomColor.kDarkInputFill
                          : CustomColor.kUltraLightBg,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 15,
                    style: (isDark
                            ? AppTextStyles.bodyMdOnDark
                            : AppTextStyles.bodyMd)
                        .copyWith(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: isDark
                          ? AppTextStyles.captionOnDark
                          : AppTextStyles.caption,
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 14.h),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                        borderSide: BorderSide(
                            color: isDark
                                ? CustomColor.kDarkBorder
                                : CustomColor.kLightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                        borderSide: BorderSide(
                            color: isDark
                                ? CustomColor.kDarkBorder
                                : CustomColor.kLightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                        borderSide:
                            const BorderSide(color: CustomColor.kPrimaryColor),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? CustomColor.kDarkInputFill
                          : CustomColor.kUltraLightBg,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 48.h,
              child: FilledButton.icon(
                onPressed: _loading ? null : _search,
                style: FilledButton.styleFrom(
                  backgroundColor: CustomColor.kPrimaryFill,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl.r)),
                ),
                icon: _loading
                    ? SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CustomColor.kTextOnDark,
                        ),
                      )
                    : Icon(Icons.search_rounded, size: 20.r),
                label: Text(
                  _loading ? 'Searching...' : 'Search',
                  style: AppTextStyles.label
                      .copyWith(color: CustomColor.kTextOnDark),
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: CustomColor.kDangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: CustomColor.kDangerRed, size: 20.r),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(_error!,
                          style: AppTextStyles.bodySm
                              .copyWith(color: CustomColor.kDangerRed)),
                    ),
                  ],
                ),
              ),
            ],
            if (_foundUser != null) ...[
              SizedBox(height: 24.h),
              _buildUserCard(_foundUser!),
            ],
            if (_notFound) ...[
              SizedBox(height: 40.h),
              _buildNotFoundState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final name =
        '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'.trim();
    final avatar = user.userImage?.isNotEmpty == true
        ? CachedNetworkImageProvider(
            '${Endpoints.mediaBaseUrl}${user.userImage}')
        : const AssetImage(AppAssets.defaultProfilePic) as ImageProvider;

    return Container(
      decoration: BoxDecoration(
        color: CustomColor.kTextOnDark,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        border: Border.all(color: CustomColor.kScrim20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundImage: avatar,
            onBackgroundImageError: (_, __) {},
            backgroundColor: CustomColor.kUltraLightPrimary,
            child: user.userImage?.isNotEmpty != true
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTextStyles.headingLg
                        .copyWith(color: CustomColor.kPrimaryColor),
                  )
                : null,
          ),
          SizedBox(height: 12.h),
          Text(name,
              style:
                  AppTextStyles.headingMd.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          SizedBox(height: 4.h),
          Text(
            '+${user.userMobileNum ?? ''}',
            style: AppTextStyles.bodySm
                .copyWith(color: CustomColor.kTextSecondary),
          ),
          SizedBox(height: 4.h),
          if ((user.userBio ?? '').isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                user.userBio!,
                style: AppTextStyles.caption
                    .copyWith(color: CustomColor.kTextTertiary),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Message',
                  color: CustomColor.kPrimaryColor,
                  onTap: () => _openChat(user),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ActionButton(
                  icon: Icons.person_add_rounded,
                  label: 'Add Contact',
                  color: CustomColor.kOnlineGreen,
                  onTap: () => _addContact(user),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ActionButton(
                  icon: Icons.schedule_send_rounded,
                  label: 'Schedule',
                  color: CustomColor.kGoldAccent,
                  onTap: () => _openSchedule(user),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Column(
      children: [
        Container(
          width: 68.r,
          height: 68.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CustomColor.kUltraLightPrimary,
            borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
          ),
          child: Icon(Icons.person_search_rounded,
              size: 32.r, color: CustomColor.kTextTertiary),
        ),
        SizedBox(height: 16.h),
        Text(
          'User not found on Humming Bird',
          textAlign: TextAlign.center,
          style: AppTextStyles.headingSm.copyWith(
              fontWeight: FontWeight.w700, color: CustomColor.kTextSecondary),
        ),
        SizedBox(height: 8.h),
        Text(
          'This number is not registered with Humming Bird.',
          textAlign: TextAlign.center,
          style:
              AppTextStyles.bodySm.copyWith(color: CustomColor.kTextTertiary),
        ),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: FilledButton.icon(
            onPressed: _inviteUser,
            style: FilledButton.styleFrom(
              backgroundColor: CustomColor.kPrimaryFill,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl.r)),
            ),
            icon: Icon(Icons.share_rounded, size: 20.r),
            label: Text(
              'Invite User',
              style:
                  AppTextStyles.label.copyWith(color: CustomColor.kTextOnDark),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22.r),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
