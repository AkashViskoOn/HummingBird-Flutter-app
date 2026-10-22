import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/room_api.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_radius.dart';

class GroupMembersOptions extends StatelessWidget {
  final String roomId;
  final User user;
  final bool isMe;
  const GroupMembersOptions(
      {super.key, required this.roomId, required this.user, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.find();
    final bool isAdmin = groupController.checkIfUserAdmin();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: Get.width * 0.82,
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: CustomColor.kTextOnDark,
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionTile(
              icon: Icons.chat_rounded,
              label: 'Message ${user.userFirstName}',
              color: CustomColor.kPrimaryColor,
              onTap: () async {
                final userController = Get.find<UserController>();
                final contactController = Get.find<ContactController>();
                final existing = contactController.checkIfRoomExists(user);
                if (existing.$1 && existing.$2?.rId != null) {
                  Get.off(() => ChatScreen(
                        name:
                            '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                                .trim(),
                        roomId: existing.$2!.rId!,
                        userNumber: user.userMobileNum ?? '',
                        receiverId: user.userId ?? '',
                        userProfile: user.userImage ?? '',
                      ));
                } else {
                  final myNumber = userController.user?.userMobileNum ?? '';
                  final result = await RoomApi().createRoom(
                    0,
                    '',
                    [myNumber, user.userMobileNum ?? ''],
                  );
                  if (result?.status == true && result!.room != null) {
                    final newRoom = result.room!;
                    contactController.homeController.singleChatsList
                        .insert(0, newRoom);
                    contactController.homeController.update(['update-card']);
                    Get.off(() => ChatScreen(
                          name:
                              '${user.userFirstName ?? ''} ${user.userLastName ?? ''}'
                                  .trim(),
                          userNumber: user.userMobileNum ?? '',
                          roomId: newRoom.rId!,
                          receiverId: user.userId ?? '',
                          userProfile: user.userImage ?? '',
                        ));
                  } else {
                    CustomSnackbar.show(
                        title: 'Error', message: 'Could not create chat');
                  }
                }
              },
            ),
            if (isAdmin) ...[
              _OptionDivider(),
              _OptionTile(
                icon: Icons.person_remove_rounded,
                label: 'Remove from Group',
                color: CustomColor.kDangerRed,
                onTap: () {
                  groupController.leaveGroup(roomId, user: user);
                },
              ),
            ],
            if (isAdmin) ...[
              _OptionDivider(),
              _OptionTile(
                icon: groupController.checkIfAdmin(user: user)
                    ? Icons.undo_rounded
                    : Icons.admin_panel_settings_rounded,
                label: groupController.checkIfAdmin(user: user)
                    ? 'Remove ${user.userFirstName} as Admin'
                    : 'Make ${user.userFirstName} Admin',
                color: CustomColor.kGoldAccent,
                onTap: () {
                  groupController.checkIfAdmin(user: user)
                      ? groupController.removeUserAsAdmin(roomId, user.userId)
                      : groupController.makeUserAdmin(roomId, user.userId);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                height: 36.r,
                width: 36.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                ),
                child: Icon(icon, size: 18.r, color: color),
              ),
              SizedBox(width: 14.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Divider(
        height: 1,
        thickness: 1,
        color: CustomColor.kTextTertiary.withValues(alpha: 0.1),
      ),
    );
  }
}
