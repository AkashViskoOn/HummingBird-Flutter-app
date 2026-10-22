import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/chat_ui/block_user_dialog.dart';
import 'package:humming_bird/components/chat_ui/report_dialog.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_message_search_page.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class ChatScreenOptionsDropdown extends StatelessWidget {
  final String userName;
  final String userNumber;
  final String roomId;
  const ChatScreenOptionsDropdown(
      {super.key,
      required this.userName,
      required this.userNumber,
      required this.roomId});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.find();
    ChatController chatController = Get.find();
    return PopupMenuButton(
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(16.r))),
      elevation: 4,
      color: CustomColor.kWhite,
      surfaceTintColor: Colors.transparent,
      itemBuilder: (context) {
        var userid = contactController.getUserIdByNumber(userNumber);
        var isBlocked = contactController.checkIfUserIsBlocked(userid);
        return [
          PopupMenuItem(
            onTap: () {
              Future.microtask(
                () => Get.to(
                  () => ChatMessageSearchPage(title: userName),
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
          if (chatController.canEditSelectedMessage)
            PopupMenuItem(
              onTap: () => chatController.editMessageFromChatScreen(),
              height: 15.h,
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
              child: Text(
                'Edit Message',
                style: AppTextStyles.headingSm
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
            ),
          PopupMenuItem(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => BlockUserDialog(
                      userId: contactController.getUserIdByNumber(userNumber),
                      userName: userName.split(' ')[0]));
            },
            height: 15.h,
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
            child: Text(
              isBlocked
                  ? 'Unblock ${userName.split(' ')[0]}'
                  : 'Block ${userName.split(' ')[0]}',
              style: AppTextStyles.headingSm
                  .copyWith(color: CustomColor.kTextPrimary),
            ),
          ),
          PopupMenuItem(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => ReportDialog(
                      userId: contactController.getUserIdByNumber(userNumber),
                      userName: userName.split(' ')[0]));
            },
            height: 15.h,
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 7.h),
            child: Text(
              'Report ${userName.split(' ')[0]}',
              style: AppTextStyles.headingSm
                  .copyWith(color: CustomColor.kDangerRed),
            ),
          ),
        ];
      },
    );
  }
}
