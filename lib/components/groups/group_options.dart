import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_screen.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_message_search_page.dart';
import 'package:humming_bird/pages/groups/message_info.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class GroupOptions extends StatelessWidget {
  final String roomId;
  const GroupOptions({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    GroupController groupController = Get.find();
    final groupName = groupController.getUpdatedGroup(roomId).rName ?? 'Group';
    return PopupMenuButton(
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.r),
              bottomRight: Radius.circular(15.r),
              bottomLeft: Radius.circular(15.r))),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            onTap: () {
              Future.microtask(
                () => Get.to(
                  () => const ChatMessageSearchPage(title: 'Group chat'),
                ),
              );
            },
            height: 15.h,
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
            child: Text(
              'Search messages',
              style: AppTextStyles.headingSm
                  .copyWith(color: CustomColor.kTextPrimary),
            ),
          ),
          PopupMenuItem(
            onTap: () {
              chatController.textMessageController.text = 'Group Event: ';
              chatController.scheduleOn = true;
              Get.to(() => ScheduleScreen(
                    name: groupName,
                    roomId: roomId,
                    receiverId: '',
                    roomUsers: '',
                    forGroup: true,
                  ));
            },
            height: 15.h,
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
            child: Row(
              children: [
                Icon(Icons.event_rounded,
                    size: 18.r, color: CustomColor.kPrimaryColor),
                SizedBox(width: 8.w),
                Text(
                  'Create Group Event',
                  style: AppTextStyles.headingSm
                      .copyWith(color: CustomColor.kTextPrimary),
                ),
              ],
            ),
          ),
          if (chatController.messageSelectorMap.length == 1 &&
              chatController.youMessages.isEmpty)
            PopupMenuItem(
              onTap: () {
                showMessageInfoSheet(
                    chatController.messageSelectorMap.keys.toList()[0]);
              },
              height: 15.h,
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
              child: Text(
                'Info',
                style: AppTextStyles.headingSm
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
            ),
        ];
      },
    );
  }
}
