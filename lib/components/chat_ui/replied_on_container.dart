import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/services/link_preview_service.dart';
import 'package:humming_bird/components/chat_ui/widgets/reply_media_thumb.dart';

class RepliedOnContainer extends StatelessWidget {
  final String messageId;
  final Color? replyColor;
  final double? textSize;
  const RepliedOnContainer({
    super.key,
    required this.messageId,
    this.replyColor,
    this.textSize,
  });

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    Messages? msg = LocalDatabase.getSingleMessages(messageId);
    final tint = replyColor ?? CustomColor.kUltraLightPrimary;
    final size = textSize ?? 11.0;
    return msg != null
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 0.55.sw,
            ),
            child: InkWell(
              onTap: () {
                chatController.scrollToMessage(messageId);
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: AppSpacing.xs.h, horizontal: AppSpacing.lg.w),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl.r),
                    topRight: Radius.circular(AppRadius.xl.r),
                    bottomRight: Radius.circular(AppRadius.xl.r),
                  ),
                  boxShadow: AppShadow.cardLight,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.reply_rounded,
                        size: AppIcons.xs.r, color: CustomColor.kTextSecondary),
                    SizedBox(width: AppSpacing.xs.w),
                    if (msg.mMessageType != null &&
                        msg.mMessageType!.trim() != '0') ...[
                      ReplyMediaThumb(message: msg, size: 26),
                      SizedBox(width: AppSpacing.sm.w),
                    ],
                    Flexible(
                      child: Text(
                        msg.mMessageType == '0'
                            ? (LinkPreviewService.isLink(msg.mMessage)
                                ? LinkPreviewService.linkSummary(msg.mMessage)
                                : (msg.mMessage ?? ''))
                            : AppHelper.getMediaName(
                                fileType: msg.mMessageType!),
                        style: AppTextStyles.label.copyWith(
                          fontSize: size.sp,
                          color: CustomColor.kTextSecondary,
                          letterSpacing: null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}
