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

class StarredMessagesPage extends StatelessWidget {
  const StarredMessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    chatController.loadStarredMessages();

    return Scaffold(
      appBar: CommonAppBar(title: 'Starred Messages'),
      body: Obx(() {
        if (chatController.starredMessages.isEmpty) {
          return const AppEmptyState(
            icon: Icons.star_outline_rounded,
            title: 'No starred messages',
            message: 'Star a message to find it here.',
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.xxl.r),
          itemCount: chatController.starredMessages.length,
          itemBuilder: (context, index) {
            final msg = chatController.starredMessages[index];
            return Card(
              margin: EdgeInsets.only(bottom: AppSpacing.md.h),
              child: ListTile(
                leading:
                    Icon(Icons.star_rounded, color: CustomColor.kGoldAccent),
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
                  tooltip: 'Starred messages',
                  icon:
                      Icon(Icons.star_rounded, color: CustomColor.kGoldAccent),
                  onPressed: () => chatController.unstarMessage(msg.mId!),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
