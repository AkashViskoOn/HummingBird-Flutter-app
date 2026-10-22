import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';

class DeleteMessageDialog extends StatelessWidget {
  const DeleteMessageDialog({super.key});

  /// "Delete for everyone" is only offered for messages I sent whose original
  /// send time is within the last hour. Older messages fall back to
  /// "Delete for me" only.
  bool _isDeleteForEveryoneAllowed(ChatController chatController) {
    if (chatController.youMessages.isEmpty) return false;
    final selectedIds =
        chatController.messageSelectorMap.keys.cast<String>().toSet();
    final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cutoffEpoch = nowEpoch - 3600;
    var foundSelectedMine = false;
    for (final id in chatController.youMessages) {
      if (!selectedIds.contains(id)) continue;
      foundSelectedMine = true;
      Messages? message;
      for (final m in chatController.messages) {
        if (m.mId == id) {
          message = m;
          break;
        }
      }
      final sentEpoch = message?.sentEpochSeconds ?? 0;
      if (sentEpoch <= 0 || sentEpoch < cutoffEpoch) return false;
    }
    return foundSelectedMine;
  }

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return Dialog(
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: Get.width * 0.8,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xxxl.r)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ' Delete Message',
                  style: AppTextStyles.headingXl,
                ),
                SizedBox(
                  height: Get.height * 0.02,
                ),
                _isDeleteForEveryoneAllowed(chatController)
                    ? TextButton(
                        onPressed: () {
                          chatController.deleteMessage(
                              chatController.messageSelectorMap.keys
                                  .cast<String>()
                                  .toList(),
                              '1',
                              true);
                        },
                        child: Text(
                          'Delete for everyone',
                          style: AppTextStyles.headingSm
                              .copyWith(color: CustomColor.kDangerRed),
                        ))
                    : const SizedBox.shrink(),
                TextButton(
                    onPressed: () {
                      chatController.deleteMessage(
                          chatController.messageSelectorMap.keys
                              .cast<String>()
                              .toList(),
                          '0',
                          true);
                    },
                    child: Text(
                      'Delete for me',
                      style: AppTextStyles.headingSm
                          .copyWith(color: CustomColor.kDangerRed),
                    )),
              ],
            ),
          ),
          Positioned(
            top: 8.h,
            right: 8.w,
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.close_rounded,
                color: CustomColor.kTextTertiary,
                size: AppIcons.xxl.r,
              ),
            ),
          )
        ],
      ),
    );
  }
}
