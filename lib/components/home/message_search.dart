import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/chat_ui/chat_card.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class SearchedMessages extends StatelessWidget {
  const SearchedMessages({super.key});

  @override
  Widget build(BuildContext context) {
    HomeController homeController = Get.find();
    ContactController contactController = Get.find();
    ChatController chatController = Get.find();
    return GetBuilder<HomeController>(
      id: 'search-update',
      builder: (_) {
        return homeController.searchedMessages.isNotEmpty ||
                homeController.singleChatsList.isNotEmpty
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 15.w),
                      child: Text(
                        'Chats',
                        style: AppTextStyles.headingSm,
                      ),
                    ),
                    SizedBox(
                      height: 0.h,
                    ),
                    homeController.singleChatsList.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'No chats found',
                            message: 'Try a different name or number.',
                            layout: EmptyStateLayout.inline,
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: homeController.singleChatsList.length,
                            itemBuilder: (context, index) {
                              Rooms room =
                                  homeController.singleChatsList[index];
                              (String, String, String, String) receiverData =
                                  contactController.getContactData(room);
                              return receiverData.$1.isNotEmpty
                                  ? GetBuilder<HomeController>(
                                      id: 'update-card',
                                      builder: (_) {
                                        return ChatCard(
                                          name: receiverData.$1,
                                          receiverId: receiverData.$2,
                                          lastMessage:
                                              room.rLastMessage?.mMessage ?? '',
                                          roomUsers: room.rUsers!,
                                          lastMessageTime:
                                              room.rLastMessage?.mUpdatedAt !=
                                                      null
                                                  ? AppHelper.formatDateTime(
                                                      DateTime.parse(room
                                                          .rLastMessage!
                                                          .mUpdatedAt!),
                                                      'hh:mm a')
                                                  : '',
                                          newMessageCounter: chatController
                                              .updateRoomUI(room.rId!),
                                          roomId: room.rId!,
                                        );
                                      })
                                  : FutureBuilder(
                                      future: contactController
                                          .getUserNumberById(room),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          return ChatCard(
                                            roomUsers: room.rUsers!,
                                            receiverId: '',
                                            name: snapshot.data.toString(),
                                            lastMessage:
                                                room.rLastMessage?.mMessage ??
                                                    '',
                                            lastMessageTime:
                                                room.rLastMessage?.mUpdatedAt !=
                                                        null
                                                    ? AppHelper.formatDateTime(
                                                        DateTime.parse(room
                                                            .rLastMessage!
                                                            .mUpdatedAt!),
                                                        'hh:mm a')
                                                    : '',
                                            newMessageCounter: chatController
                                                .updateRoomUI(room.rId!),
                                            roomId: room.rId!,
                                          );
                                        } else {
                                          return const CustomLoading();
                                        }
                                      },
                                    );
                            },
                          ),
                    SizedBox(
                      height: 15.h,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 15.w),
                      child: Text(
                        'Messages',
                        style: AppTextStyles.titleSm,
                      ),
                    ),
                    SizedBox(
                      height: 5.h,
                    ),
                    homeController.searchedMessages.isEmpty
                        ? const AppEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No messages found',
                            message: 'Try a different search term.',
                            layout: EmptyStateLayout.inline,
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: homeController.searchedMessages.length,
                            itemBuilder: (context, index) {
                              Messages result =
                                  homeController.searchedMessages[index];
                              return ListTile(
                                onTap: () {
                                  chatController.receiverId =
                                      result.mReceiverId!;

                                  Get.to(
                                      () => ChatScreen(
                                            name: contactController
                                                .getUserNameById(
                                                    result.mReceiverId!),
                                            userNumber: '',
                                            roomId: result.mRoomId!,
                                            receiverId: '',
                                            isGroup: false,
                                            userProfile: contactController
                                                .getUserProfilePic(
                                                    result.mReceiverId!),
                                          ),
                                      arguments: {
                                        'isScroll': true,
                                        'messageId': result.mId!
                                      });
                                },
                                title: Text(
                                  result.mMessage.toString(),
                                  style: AppTextStyles.headingSm
                                      .copyWith(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                    'In Chat: ${contactController.getUserNameById(result.mReceiverId!)}',
                                    style: AppTextStyles.chatPreview),
                                trailing: Text(
                                  AppHelper.formatDateTime(
                                      DateTime.parse(result.mUpdatedAt!),
                                      'hh:mm a'),
                                  style: AppTextStyles.bodyMd.copyWith(
                                      color: CustomColor.kTextTertiary),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              )
            : const AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'Nothing found',
                message: 'Search your chats and messages to find them here.',
              );
      },
    );
  }
}
