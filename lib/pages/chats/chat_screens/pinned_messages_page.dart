import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';

class PinnedMessagesPage extends StatelessWidget {
  final String roomId;

  const PinnedMessagesPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    chatController.loadPinnedMessages(roomId);

    return Scaffold(
      appBar: CommonAppBar(title: 'Pinned Messages'),
      body: Obx(() {
        if (chatController.pinnedMessages.isEmpty) {
          return const AppEmptyState(
            icon: Icons.push_pin_outlined,
            title: 'No pinned messages',
            message: 'Pin a message in a chat to find it here.',
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.xxl.r),
          itemCount: chatController.pinnedMessages.length,
          itemBuilder: (context, index) {
            final msg = chatController.pinnedMessages[index];
            return Card(
              margin: EdgeInsets.only(bottom: AppSpacing.md.h),
              child: ListTile(
                leading: Icon(Icons.push_pin_rounded,
                    color: CustomColor.kPrimaryColor),
                title: Text(
                  msg.mMessage ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd,
                ),
                subtitle: Text(
                  AppHelper.formatTime(msg.mCreatedAt),
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kTextTertiary),
                ),
                trailing: IconButton(
                  tooltip: 'Pinned messages',
                  icon: Icon(Icons.push_pin_outlined,
                      color: CustomColor.kPrimaryColor),
                  onPressed: () => chatController.unpinMessage(msg.mId!),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
