import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ChatByPhoneScreen extends StatefulWidget {
  const ChatByPhoneScreen({super.key});

  @override
  State<ChatByPhoneScreen> createState() => _ChatByPhoneScreenState();
}

class _ChatByPhoneScreenState extends State<ChatByPhoneScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController(text: '+91');
  final ContactController _contactCtrl = Get.find();
  final UserController _userCtrl = Get.find();
  final RoomApi _roomApi = RoomApi();

  bool _loading = false;
  String? _error;

  static const _countryCodes = [
    '+91',
    '+1',
    '+44',
    '+61',
    '+81',
    '+86',
    '+49',
    '+33',
    '+39',
    '+34',
    '+7',
    '+55',
    '+82',
    '+31',
    '+46',
    '+41',
    '+971',
    '+966',
    '+65',
    '+60',
    '+63',
    '+62',
    '+84',
    '+90',
    '+30',
    '+48',
    '+43',
    '+32',
    '+47',
    '+45',
    '+358',
    '+351',
    '+353',
    '+27',
    '+20',
    '+212',
    '+234',
    '+254',
    '+233',
    '+92',
    '+880',
    '+977',
    '+94',
    '+95',
    '+66',
    '+856',
    '+84',
    '+855',
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String get _cleanPhone {
    final code = _codeCtrl.text.replaceAll(RegExp(r'\D'), '');
    final num = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    return '$code$num';
  }

  bool get _isValid {
    final code = _codeCtrl.text.replaceAll(RegExp(r'\D'), '');
    final num = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (code.isEmpty || num.isEmpty) return false;
    if (num.length < 5 || num.length > 15) return false;
    if (!_countryCodes.contains('+$code') &&
        !_countryCodes.contains(_codeCtrl.text.trim())) {
      return false;
    }
    return true;
  }

  Future<void> _continue() async {
    if (!_isValid) {
      setState(() => _error = 'Please enter a valid phone number');
      return;
    }

    final phone = _cleanPhone;
    final myNumber = _userCtrl.user?.userMobileNum ?? '';
    if (phone == myNumber.replaceAll(RegExp(r'\D'), '')) {
      setState(() => _error = 'You cannot message yourself');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _roomApi.checkUserByNumber(phone);
      if (!mounted) return;

      if (result['exists'] == true) {
        final user = User.fromJson(Map<String, dynamic>.from(result['user']));
        final existing = _contactCtrl.checkIfRoomExists(user);
        if (existing.$1 && existing.$2?.rId != null) {
          Get.to(() => ChatScreen(
                name: '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                    .trim(),
                userNumber: user.userMobileNum ?? '',
                roomId: existing.$2!.rId!,
                userProfile: user.userImage ?? '',
                receiverId: user.userId ?? '',
              ));
        } else {
          final myNumber = _userCtrl.user?.userMobileNum ?? '';
          final roomResult = await _roomApi
              .createRoom(0, '', [myNumber, user.userMobileNum ?? '']);
          if (roomResult?.status == true && roomResult!.room != null) {
            final newRoom = roomResult.room!;
            _contactCtrl.homeController.singleChatsList.insert(0, newRoom);
            _contactCtrl.homeController.update(['update-card']);
            Get.to(() => ChatScreen(
                  name: '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                      .trim(),
                  userNumber: user.userMobileNum ?? '',
                  roomId: newRoom.rId!,
                  userProfile: user.userImage ?? '',
                  receiverId: user.userId ?? '',
                ));
          } else {
            CustomSnackbar.show(
                title: 'Error', message: 'Could not create chat');
          }
        }
      } else {
        final room = await _roomApi.createPendingRoom(phone);
        if (!mounted) return;
        if (room != null) {
          Get.to(() => ChatScreen(
                name: phone,
                userNumber: phone,
                roomId: room.room?.rId ?? '0',
                receiverId: '',
                userProfile: '',
                isPending: true,
              ));
        } else {
          setState(() => _error = 'Failed to create conversation');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      appBar: CommonAppBar(title: 'Message Any Mobile Number'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20.w, 20.w, 20.w, 20.w + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text(
              'Enter the phone number you want to message',
              style: AppTextStyles.bodyMd.copyWith(
                  color: isDark
                      ? CustomColor.kTextOnDarkMuted
                      : CustomColor.kTextTertiary),
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                SizedBox(
                  width: 100.w,
                  child: TextField(
                    controller: _codeCtrl,
                    style: AppTextStyles.headingSm,
                    decoration: InputDecoration(
                      labelText: 'Code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 14.h),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    style: AppTextStyles.headingSm,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 14.h),
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 15,
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Text(
                _error!,
                style: AppTextStyles.subtitle
                    .copyWith(color: CustomColor.kDangerRed),
              ),
            ],
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColor.kPrimaryFill,
                  foregroundColor: CustomColor.kTextOnDark,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: CircularProgressIndicator(
                            color: CustomColor.kTextOnDark, strokeWidth: 2),
                      )
                    : Text(
                        'Continue',
                        style: AppTextStyles.headingSm,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
